defmodule Asciinema.Accounts do
  import Ecto.Query, warn: false
  import Ecto, only: [assoc: 2, build_assoc: 2]
  alias Asciinema.Accounts.{User, ApiToken}
  alias Asciinema.{Repo, Asciicasts, Email, Mailer}

  def create_asciinema_user!() do
    attrs = %{username: "asciinema",
              name: "asciinema",
              email: "admin@asciinema.org"}

    user = case Repo.get_by(User, username: "asciinema") do
             nil ->
               %User{}
               |> User.create_changeset(attrs)
               |> Repo.insert!
             user ->
               user
           end

    if Repo.count(assoc(user, :asciicasts)) == 0 do
      upload = %Plug.Upload{path: "priv/welcome.json",
                            filename: "asciicast.json",
                            content_type: "application/json"}

      {:ok, _} = Asciicasts.create_asciicast(user, upload, %{private: false, snapshot_at: 76.2})
    end

    :ok
  end

  def change_user(user) do
    User.changeset(user)
  end

  def update_user(user, params) do
    user
    |> User.update_changeset(params)
    |> Repo.update
  end

  def send_login_email(email_or_username) do
    with {:ok, %User{} = user} <- lookup_user(email_or_username) do
      do_send_login_email(user)
    end
  end

  defp lookup_user(email_or_username) do
    if String.contains?(email_or_username, "@") do
      lookup_user_by_email(email_or_username)
    else
      lookup_user_by_username(email_or_username)
    end
  end

  defp lookup_user_by_email(email) do
    case Repo.get_by(User, email: email) do
      %User{} = user ->
        {:ok, user}
      nil ->
        case User.signup_changeset(%{email: email}) do
          %{errors: [{:email, _}]} ->
            {:error, :email_invalid}
          %{errors: []} ->
            {:ok, %User{email: email}}
        end
    end
  end

  defp lookup_user_by_username(username) do
    case Repo.get_by(User, username: username) do
      %User{} = user ->
        {:ok, user}
      nil ->
        {:error, :user_not_found}
    end
  end

  defp do_send_login_email(%User{email: nil}) do
    {:error, :email_missing}
  end
  defp do_send_login_email(%User{id: nil, email: email}) do
    url = signup_url(email)
    Email.signup_email(email, url) |> Mailer.deliver_later
    {:ok, url}
  end
  defp do_send_login_email(%User{} = user) do
    url = login_url(user)
    Email.login_email(user.email, url) |> Mailer.deliver_later
    {:ok, url}
  end

  def signup_token(email) do
    Phoenix.Token.sign(AsciinemaWeb.Endpoint, "signup", email)
  end

  def signup_url(email) do
    token = signup_token(email)
    AsciinemaWeb.Router.Helpers.users_url(AsciinemaWeb.Endpoint, :new, t: token)
  end

  def login_token(%User{id: id, last_login_at: last_login_at}) do
    last_login_at = last_login_at && Timex.to_unix(last_login_at)
    Phoenix.Token.sign(AsciinemaWeb.Endpoint, "login", {id, last_login_at})
  end

  def login_url(%User{} = user) do
    token = login_token(user)
    AsciinemaWeb.Router.Helpers.session_url(AsciinemaWeb.Endpoint, :new, t: token)
  end

  @login_token_max_age 15 * 60 # 15 minutes

  alias Phoenix.Token
  alias AsciinemaWeb.Endpoint

  def verify_signup_token(token) do
    with {:ok, email} <- Token.verify(Endpoint, "signup", token, max_age: @login_token_max_age),
         {:ok, %User{} = user} <- Repo.insert(User.signup_changeset(%{email: email})) do
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
    with {:ok, {user_id, last_login_at}} <- Token.verify(Endpoint, "login", token, max_age: @login_token_max_age),
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
      |> Repo.insert

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

  def get_api_token!(token) do
    Repo.get_by!(ApiToken, token: token)
  end

  def revoke_api_token!(api_token) do
    api_token
    |> ApiToken.revoke_changeset
    |> Repo.update!
  end

  def merge!(dst_user, src_user) do
    Repo.transaction(fn ->
      asciicasts_q = from(assoc(src_user, :asciicasts))
      Repo.update_all(asciicasts_q, set: [user_id: dst_user.id, updated_at: Timex.now])
      api_tokens_q = from(assoc(src_user, :api_tokens))
      Repo.update_all(api_tokens_q, set: [user_id: dst_user.id, updated_at: Timex.now])
      Repo.delete!(src_user)
      dst_user
    end)
  end

  def list_api_tokens(%User{} = user) do
    user
    |> assoc(:api_tokens)
    |> Repo.all
  end
end
