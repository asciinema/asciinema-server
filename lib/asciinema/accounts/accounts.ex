defmodule Asciinema.Accounts do
  use Asciinema.Config
  import Ecto.Query, warn: false
  import Ecto, only: [assoc: 2, build_assoc: 2]
  alias Asciinema.Accounts.{User, ApiToken}
  alias Asciinema.{Emails, Repo}
  alias Ecto.Changeset

  def fetch_user(id) do
    case get_user(id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def get_user(id) when is_integer(id), do: Repo.get(User, id)

  def get_user([{_k, _v}] = kv), do: Repo.get_by(User, kv)

  def ensure_asciinema_user do
    case Repo.get_by(User, username: "asciinema") do
      nil ->
        attrs = %{
          username: "asciinema",
          name: "asciinema",
          email: "admin@asciinema.org"
        }

        %User{}
        |> User.create_changeset(attrs)
        |> Repo.insert!()

      user ->
        user
    end
  end

  def change_user(user) do
    User.changeset(user)
  end

  def update_user(user, params) do
    user
    |> User.update_changeset(params)
    |> Repo.update()
  end

  def temporary_user?(user), do: user.email == nil

  def temporary_users(q \\ User) do
    from(u in q, where: is_nil(u.email))
  end

  def send_login_email(email_or_username, signup_url, login_url, sign_up_enabled?) do
    case {lookup_user(email_or_username), sign_up_enabled?} do
      {%User{email: nil}, _} ->
        {:error, :email_missing}

      {%User{} = user, _} ->
        url = user |> login_token() |> login_url.()
        {:ok, _} = Emails.send_login_email(user.email, url)

        :ok

      {%Changeset{errors: [{:email, _}]}, _} ->
        {:error, :email_invalid}

      {%Changeset{} = changeset, true} ->
        email = changeset.changes.email
        url = email |> signup_token() |> signup_url.()
        {:ok, _} = Emails.send_signup_email(email, url)

        :ok

      {%Changeset{}, false} ->
        {:error, :user_not_found}

      {nil, _} ->
        {:error, :user_not_found}
    end
  end

  def lookup_user(email_or_username) do
    if String.contains?(email_or_username, "@") do
      Repo.get_by(User, email: email_or_username) ||
        User.signup_changeset(%{email: email_or_username})
    else
      Repo.get_by(User, username: email_or_username)
    end
  end

  alias Phoenix.Token

  def signup_token(email) do
    Token.sign(config(:secret), "signup", email)
  end

  def login_token(%User{id: id, last_login_at: last_login_at}) do
    last_login_at = last_login_at && Timex.to_unix(last_login_at)
    Token.sign(config(:secret), "login", {id, last_login_at})
  end

  # 15 minutes
  @login_token_max_age 15 * 60

  def verify_signup_token(token) do
    result =
      Token.verify(
        config(:secret),
        "signup",
        token,
        max_age: @login_token_max_age
      )

    with {:ok, email} <- result,
         {:ok, user} <- %{email: email} |> User.signup_changeset() |> Repo.insert() do
      {:ok, user}
    else
      {:error, :invalid} ->
        {:error, :token_invalid}

      {:error, %Ecto.Changeset{}} ->
        {:error, :email_taken}

      {:error, _} ->
        {:error, :token_expired}
    end
  end

  def verify_login_token(token) do
    result =
      Token.verify(
        config(:secret),
        "login",
        token,
        max_age: @login_token_max_age
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

  def get_user_with_api_token(token, tmp_username \\ nil) do
    case get_api_token(token) do
      {:ok, %ApiToken{user: user}} ->
        {:ok, user}

      {:error, :token_revoked} = res ->
        res

      {:error, :token_not_found} ->
        create_user_with_api_token(token, tmp_username)
    end
  end

  def create_user_with_api_token(token, tmp_username) do
    user_changeset = User.temporary_changeset(tmp_username)

    Repo.transaction(fn ->
      with {:ok, %User{} = user} <- Repo.insert(user_changeset),
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

  def get_or_create_api_token(token, user) do
    with {:ok, token} <- get_api_token(token) do
      {:ok, token}
    else
      {:error, :token_not_found} ->
        create_api_token(user, token)

      otherwise ->
        otherwise
    end
  end

  def get_api_token(token) do
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

  def get_api_token!(user, id) do
    Repo.get!(assoc(user, :api_tokens), id)
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

  def add_admins(emails) do
    from(u in User, where: u.email in ^emails)
    |> Repo.update_all(set: [is_admin: true])
  end

  def remove_admins(emails) do
    from(u in User, where: u.email in ^emails)
    |> Repo.update_all(set: [is_admin: false])
  end

  def delete_user!(%User{} = user) do
    Repo.delete!(user)
  end
end
