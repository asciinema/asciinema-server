defmodule Asciinema.Accounts do
  use Asciinema.Config
  import Ecto.Query, warn: false
  import Ecto, only: [assoc: 2, build_assoc: 2]
  alias Asciinema.Accounts.{User, ApiToken}
  alias Asciinema.{Fonts, Repo, Themes}
  alias Ecto.Changeset
  alias Phoenix.Token

  @valid_email_re ~r/^[A-Z0-9._%+-]+@([A-Z0-9-]+\.)+[A-Z]{2,}$/i
  @valid_username_re ~r/^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$/

  def fetch_user(id) do
    case get_user(id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def get_user([{_k, _v}] = kv), do: Repo.get_by(User, kv)

  def get_user(id), do: Repo.get(User, id)

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

  def create_user(attrs) do
    import Ecto.Changeset

    result =
      %User{}
      |> cast(attrs, [:email])
      |> validate_required([:email])
      |> update_change(:email, &String.downcase/1)
      |> validate_format(:email, @valid_email_re)
      |> add_contraints()
      |> Repo.insert()

    with {:error, %Ecto.Changeset{errors: [{:email, _}]}} <- result do
      {:error, :email_taken}
    end
  end

  def ensure_asciinema_user do
    case Repo.get_by(User, username: "asciinema") do
      nil ->
        attrs = %{
          username: "asciinema",
          name: "asciinema",
          email: "admin@asciinema.org"
        }

        %User{}
        |> change_user(attrs)
        |> Repo.insert!()

      user ->
        user
    end
  end

  def change_user(user, params \\ %{}) do
    import Ecto.Changeset

    user
    |> cast(params, [
      :email,
      :name,
      :username,
      :theme_name,
      :theme_prefer_original,
      :terminal_font_family,
      :default_asciicast_visibility
    ])
    |> validate_required([:email])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @valid_email_re)
    |> validate_format(:username, @valid_username_re)
    |> validate_length(:username, min: 2, max: 16)
    |> validate_inclusion(:theme_name, Themes.terminal_themes())
    |> validate_inclusion(:terminal_font_family, Fonts.terminal_font_families())
    |> add_contraints()
  end

  defp add_contraints(changeset) do
    import Ecto.Changeset

    changeset
    |> unique_constraint(:username, name: "index_users_on_username")
    |> unique_constraint(:email, name: "index_users_on_email")
  end

  def update_user(user, params) do
    import Ecto.Changeset

    user
    |> change_user(params)
    |> validate_required([:username])
    |> Repo.update()
  end

  def temporary_user?(user), do: user.email == nil

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

        if changeset.valid? do
          email = changeset.changes.email

          {:ok, {:sign_up, sign_up_token(email), email}}
        else
          {:error, :email_invalid}
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

  def get_user_with_api_token(token, tmp_username \\ nil) do
    case fetch_api_token(token) do
      {:ok, api_token} ->
        {:ok, api_token.user}

      {:error, :token_revoked} = result ->
        result

      {:error, :token_not_found} ->
        create_user_with_api_token(token, tmp_username)
    end
  end

  def create_user_with_api_token(token, tmp_username) do
    import Ecto.Changeset

    changeset = change(%User{}, %{temporary_username: tmp_username})

    Repo.transaction(fn ->
      with {:ok, %User{} = user} <- Repo.insert(changeset),
           {:ok, %ApiToken{}} <- create_api_token(user, token) do
        user
      else
        {:error, %Ecto.Changeset{}} ->
          Repo.rollback(:token_invalid)

        {:error, reason} ->
          Repo.rollback(reason)

        result ->
          Repo.rollback(result)
      end
    end)
  end

  def create_api_token(%User{} = user, token) do
    result =
      user
      |> build_assoc(:api_tokens)
      |> ApiToken.create_changeset(token)
      |> Repo.insert()

    case result do
      {:ok, api_token} ->
        {:ok, %{api_token | user: user}}

      {:error, %Ecto.Changeset{}} ->
        {:error, :token_invalid}
    end
  end

  def register_api_token(user, token) do
    case fetch_api_token(token) do
      {:ok, api_token} ->
        check_api_token_ownership(user, api_token)

      {:error, :token_revoked} = result ->
        result

      {:error, :token_not_found} ->
        create_api_token(user, token)
    end
  end

  defp check_api_token_ownership(user, api_token) do
    cond do
      user.id == api_token.user.id -> {:ok, api_token}
      api_token.user.email -> {:error, :token_taken}
      true -> {:error, {:needs_merge, api_token.user}}
    end
  end

  def fetch_api_token(token) do
    api_token =
      ApiToken
      |> Repo.get_by(token: token)
      |> Repo.preload(:user)

    case api_token do
      nil -> {:error, :token_not_found}
      %ApiToken{revoked_at: nil} -> {:ok, api_token}
      %ApiToken{} -> {:error, :token_revoked}
    end
  end

  def get_api_token(user, id) do
    Repo.get(assoc(user, :api_tokens), id)
  end

  def get_api_token!(token) do
    Repo.get_by!(ApiToken, token: token)
  end

  def revoke_api_token!(api_token) do
    api_token
    |> ApiToken.revoke_changeset()
    |> Repo.update!()
  end

  def list_api_tokens(%User{} = user) do
    user
    |> assoc(:api_tokens)
    |> Repo.all()
  end

  def reassign_api_tokens(src_user_id, dst_user_id) do
    q = from(at in ApiToken, where: at.user_id == ^src_user_id)
    Repo.update_all(q, set: [user_id: dst_user_id, updated_at: Timex.now()])
  end

  def regenerate_auth_token(user) do
    user
    |> Changeset.change(%{auth_token: Crypto.random_token(20)})
    |> Repo.update!()
  end

  def update_last_login(user) do
    user
    |> Changeset.change(%{last_login_at: Timex.now()})
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
    Repo.delete_all(assoc(user, :api_tokens))
    Repo.delete!(user)

    :ok
  end

  def default_theme_name(user), do: user.theme_name

  def default_font_family(user), do: user.terminal_font_family
end
