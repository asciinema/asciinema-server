defmodule Asciinema.Accounts do
  use Asciinema.Config
  import Ecto.Query, warn: false
  import Ecto, only: [assoc: 2, build_assoc: 2]
  alias Asciinema.Accounts.{Cli, User}
  alias Asciinema.{Fonts, Repo, Themes}
  alias Ecto.Changeset
  alias Phoenix.Token

  @valid_email_re ~r/^[A-Z0-9._%+-]+@([A-Z0-9-]+\.)+[A-Z]{2,}$/i
  @valid_username_re ~r/^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$/

  def get_user([{_k, _v}] = kv), do: Repo.get_by(User, kv)

  def get_user(id), do: Repo.get(User, id)

  def fetch_user(id), do: OK.required(get_user(id), :not_found)

  def find_user(%User{} = user), do: user

  def find_user(id) when is_integer(id), do: get_user(id)

  def find_user(id) when is_binary(id) do
    {_, user} = lookup_user(id)

    user
  end

  def find_user_by_username(username) do
    Repo.one(
      from(u in User,
        where: fragment("lower(?)", u.username) == ^String.downcase(username)
      )
    )
  end

  def find_user_by_auth_token(auth_token) do
    Repo.get_by(User, auth_token: auth_token)
  end

  def list_users(limit \\ 1000) do
    Repo.all(from(u in User, order_by: [asc: :id], limit: ^limit))
  end

  def build_user(attrs \\ %{}) do
    Changeset.change(
      %User{
        default_recording_visibility: config(:default_recording_visibility, :unlisted),
        default_stream_visibility: config(:default_stream_visibility, :unlisted),
        streaming_enabled: config(:default_streaming_enabled, true),
        live_stream_limit: config(:default_live_stream_limit, nil)
      },
      attrs
    )
  end

  def create_user(attrs, :user) do
    import Ecto.Changeset

    build_user()
    |> cast(attrs, [:email, :username])
    |> validate_required([:email])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @valid_email_re)
    |> validate_username()
    |> add_contraints()
    |> Repo.insert()
  end

  def create_user(attrs, :admin) do
    import Ecto.Changeset

    build_user()
    |> cast(attrs, [:email, :username])
    |> validate_required([:email])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @valid_email_re)
    |> validate_username()
    |> add_contraints()
    |> Repo.insert()
  end

  def ensure_asciinema_user do
    case Repo.get_by(User, username: "asciinema") do
      nil ->
        attrs = %{
          username: "asciinema",
          name: "asciinema",
          email: "admin@asciinema.org"
        }

        attrs
        |> build_user()
        |> Repo.insert!()

      user ->
        user
    end
  end

  def change_user(user, params \\ %{}, ctx \\ :user)

  def change_user(user, params, :user) do
    import Ecto.Changeset

    user
    |> cast(params, [
      :email,
      :name,
      :username,
      :term_theme_name,
      :term_theme_prefer_original,
      :term_font_family,
      :default_recording_visibility,
      :default_stream_visibility,
      :stream_recording_enabled
    ])
    |> validate_required([:email, :username])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @valid_email_re)
    |> validate_username()
    |> validate_inclusion(:term_theme_name, Themes.terminal_themes())
    |> validate_inclusion(:term_font_family, Fonts.terminal_font_families())
    |> add_contraints()
  end

  def change_user(user, params, :admin) do
    import Ecto.Changeset

    user
    |> cast(params, [
      :email,
      :name,
      :username,
      :streaming_enabled,
      :live_stream_limit
    ])
    |> validate_required([:email, :username])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @valid_email_re)
    |> validate_username()
    |> validate_number(:live_stream_limit, greater_than_or_equal_to: 0)
    |> add_contraints()
  end

  defp validate_username(changeset) do
    import Ecto.Changeset

    changeset
    |> validate_format(:username, @valid_username_re)
    |> validate_length(:username, min: 2, max: 16)
  end

  defp add_contraints(changeset) do
    import Ecto.Changeset

    changeset
    |> unique_constraint(:username, name: "users_username_unique_index")
    |> unique_constraint(:email, name: "users_email_index")
  end

  def update_user(user, params, ctx \\ :user) do
    user
    |> change_user(params, ctx)
    |> Repo.update()
  end

  def cli_registered?(%Cli{} = cli), do: cli.user.email != nil

  def temporary_users(q \\ User) do
    from(u in q, where: is_nil(u.email))
  end

  def sign_up_enabled?, do: config(:sign_up_enabled?, true)

  def generate_login_token(identifier, opts \\ []) do
    sign_up_enabled? = Keyword.get(opts, :register, sign_up_enabled?())

    case {lookup_user(identifier), sign_up_enabled?} do
      {{_, %User{email: nil}}, _} ->
        {:error, :email_missing}

      {{_, %User{} = user}, _} ->
        {:ok, {:login, login_token(user), user.email}}

      {{:email, nil}, true} ->
        changeset = change_user(%User{}, %{email: identifier})

        if Enum.any?(changeset.errors, &(elem(&1, 0) == :email)) do
          {:error, :email_invalid}
        else
          email = changeset.changes.email

          {:ok, {:sign_up, sign_up_token(email), email}}
        end

      {{_, nil}, _} ->
        {:error, :user_not_found}
    end
  end

  def lookup_user(identifier) when is_binary(identifier) do
    if String.contains?(identifier, "@") do
      {:email, Repo.get_by(User, email: String.downcase(identifier))}
    else
      {:username, find_user_by_username(identifier)}
    end
  end

  def sign_up_token(email) do
    Token.sign(config(:secret), "sign_up", email)
  end

  def login_token(%User{id: id, last_login_at: last_login_at}) do
    last_login_at = last_login_at && Timex.to_unix(last_login_at)
    Token.sign(config(:secret), "login", {id, last_login_at})
  end

  def verify_sign_up_token(token) do
    result =
      Token.verify(
        config(:secret),
        "sign_up",
        token,
        max_age: config(:login_token_max_age, 60) * 60
      )

    case result do
      {:ok, email} -> {:ok, email}
      {:error, :invalid} -> {:error, :token_invalid}
      {:error, _} -> {:error, :token_expired}
    end
  end

  def verify_login_token(token) do
    result =
      Token.verify(
        config(:secret),
        "login",
        token,
        max_age: config(:login_token_max_age, 60) * 60
      )

    with {:ok, {user_id, last_login_at}} <- result,
         %User{} = user <- Repo.get(User, user_id),
         ^last_login_at <- user.last_login_at && Timex.to_unix(user.last_login_at) do
      {:ok, user}
    else
      {:error, :invalid} ->
        {:error, :token_invalid}

      nil ->
        {:error, :user_not_found}

      _ ->
        {:error, :token_expired}
    end
  end

  def generate_deletion_token(%User{id: user_id}) do
    Token.sign(config(:secret), "acct-delete", user_id)
  end

  def verify_deletion_token(token) do
    case Token.verify(config(:secret), "acct-delete", token, max_age: 3600) do
      {:ok, user_id} -> {:ok, user_id}
      {:error, _} -> {:error, :token_invalid}
    end
  end

  @uuid4 ~r/\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/

  def register_cli(%User{} = user, install_id) do
    case fetch_cli(install_id) do
      {:ok, cli} ->
        check_cli_ownership(user, cli)

      {:error, :cli_revoked} = result ->
        result

      {:error, :token_not_found} ->
        create_cli(user, install_id)
    end
  end

  def register_cli(username, install_id) when is_binary(username) do
    case fetch_cli(install_id) do
      {:ok, cli} ->
        {:ok, cli}

      {:error, :cli_revoked} = result ->
        result

      {:error, :token_not_found} = result ->
        if config(:upload_auth_required, false) do
          result
        else
          create_cli(create_tmp_user(username), install_id)
        end
    end
  end

  defp create_cli(%User{} = user, install_id) do
    result =
      user
      |> new_cli(%{token: install_id})
      |> Repo.insert()

    case result do
      {:ok, cli} ->
        {:ok, %{cli | user: user}}

      {:error, %Ecto.Changeset{}} ->
        {:error, :token_invalid}
    end
  end

  def new_cli(user, attrs \\ %{}) do
    import Changeset

    user
    |> build_assoc(:clis)
    |> cast(attrs, [:token])
    |> validate_format(:token, @uuid4)
    |> unique_constraint(:token, name: "clis_token_index")
  end

  defp create_tmp_user(username) do
    %{temporary_username: String.slice(username, 0, 16)}
    |> build_user()
    |> Repo.insert!()
  end

  defp check_cli_ownership(user, cli) do
    cond do
      user.id == cli.user.id -> {:ok, cli}
      cli.user.email -> {:error, :token_taken}
      true -> {:error, {:needs_merge, cli.user}}
    end
  end

  def fetch_cli(token) do
    cli =
      Cli
      |> Repo.get_by(token: token)
      |> Repo.preload(:user)

    case cli do
      nil -> {:error, :token_not_found}
      %Cli{revoked_at: nil} -> {:ok, cli}
      %Cli{} -> {:error, :cli_revoked}
    end
  end

  def get_cli(user, id) do
    Repo.get(assoc(user, :clis), id)
  end

  def get_cli!(token) do
    Repo.get_by!(Cli, token: token)
  end

  def revoke_cli!(%Cli{revoked_at: nil} = cli) do
    cli
    |> Changeset.change(%{revoked_at: DateTime.utc_now(:second)})
    |> Repo.update!()
  end

  def revoke_cli!(cli), do: cli

  def list_clis(%User{} = user) do
    user
    |> assoc(:clis)
    |> Repo.all()
  end

  def reassign_clis(src_user_id, dst_user_id) do
    q = from(at in Cli, where: at.user_id == ^src_user_id)
    Repo.update_all(q, set: [user_id: dst_user_id, updated_at: Timex.now()])
  end

  def regenerate_auth_token(user) do
    user
    |> Changeset.change(%{auth_token: Crypto.random_token(20)})
    |> Repo.update!()
  end

  def update_last_login(user) do
    user
    |> Changeset.change(%{last_login_at: DateTime.utc_now(:second)})
    |> Repo.update!()
  end

  def add_admins(emails) do
    from(u in User, where: u.email in ^emails)
    |> Repo.update_all(set: [is_admin: true])
  end

  def remove_admins(emails) do
    from(u in User, where: u.email in ^emails)
    |> Repo.update_all(set: [is_admin: false])
  end

  def delete_user!(%User{} = user) do
    Repo.delete_all(assoc(user, :clis))
    Repo.delete!(user)

    :ok
  end

  def default_term_theme_name(user), do: user.term_theme_name

  def default_font_family(user), do: user.term_font_family
end
