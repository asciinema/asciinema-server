defmodule Asciinema.Accounts do
  import Ecto.Query, warn: false
  import Ecto, only: [assoc: 2]
  alias Asciinema.Accounts.{User, ApiToken}
  alias Asciinema.{Repo, Asciicasts, Email, Mailer}

  def create_asciinema_user!() do
    attrs = %{username: "asciinema",
              name: "asciinema",
              email: "support@asciinema.org"}

    user = case Repo.get_by(User, username: "asciinema") do
             nil ->
               %User{}
               |> User.create_changeset(attrs)
               |> Repo.insert!
             user ->
               user
           end

    if Repo.count(assoc(user, :asciicasts)) == 0 do
      upload = %Plug.Upload{path: "resources/welcome.json",
                            filename: "asciicast.json",
                            content_type: "application/json"}

      {:ok, _} = Asciicasts.create_asciicast(user, upload, %{private: false, snapshot_at: 76.2})
    end

    :ok
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

  defp signup_url(email) do
    token = Phoenix.Token.sign(AsciinemaWeb.Endpoint, "signup", email)
    AsciinemaWeb.Router.Helpers.users_url(AsciinemaWeb.Endpoint, :new, t: token)
  end

  defp login_url(%User{id: id, last_login_at: last_login_at}) do
    last_login_at = last_login_at && Timex.to_unix(last_login_at)
    token = Phoenix.Token.sign(AsciinemaWeb.Endpoint, "login", {id, last_login_at})
    AsciinemaWeb.Router.Helpers.session_url(AsciinemaWeb.Endpoint, :new, t: token)
  end

  @login_token_max_age 15 * 60 # 15 minutes

  alias Phoenix.Token
  alias AsciinemaWeb.Endpoint

  def verify_signup_token(token) do
    with {:ok, email} <- Token.verify(Endpoint, "signup", token, max_age: @login_token_max_age),
         {:ok, %User{} = user} <- User.signup_changeset(%{email: email}) |> Repo.insert do
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

  def authenticate(api_token) do
    q = from u in User,
      join: at in ApiToken,
      on: at.user_id == u.id,
      select: {u, at.revoked_at},
      where: at.token == ^api_token

    case Repo.one(q) do
      nil ->
        {:error, :token_not_found}
      {%User{} = user, nil} ->
        {:ok, user}
      {%User{}, _} ->
        {:error, :token_revoked}
    end
  end

  def get_user_with_api_token(api_token, tmp_username \\ nil) do
    case authenticate(api_token) do
      {:ok, %User{}} = res ->
        res
      {:error, :token_revoked} = res ->
        res
      {:error, :token_not_found} ->
        create_user_with_api_token(api_token, tmp_username)
    end
  end

  def create_user_with_api_token(api_token, tmp_username) do
    user_changeset = User.temporary_changeset(tmp_username)

    {_, result} = Repo.transaction(fn ->
      with {:ok, %User{} = user} <- Repo.insert(user_changeset),
           api_token_changeset = ApiToken.create_changeset(user, api_token),
           {:ok, %ApiToken{}} <- Repo.insert(api_token_changeset) do
        {:ok, user}
      else
        {:error, %Ecto.Changeset{}} ->
          {:error, :token_invalid}
        {:error, _} = err ->
          Repo.rollback(err)
        result ->
          Repo.rollback({:error, result})
      end
    end)

    result
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
end
