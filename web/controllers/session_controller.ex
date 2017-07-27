defmodule Asciinema.SessionController do
  use Asciinema.Web, :controller
  import Asciinema.UserView, only: [profile_path: 1]
  alias Asciinema.{Users, User}

  def new(conn, %{"t" => login_token}) do
    conn
    |> put_session(:login_token, login_token)
    |> redirect(to: session_path(conn, :new))
  end
  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"api_token" => api_token}) do
    case Users.get_user_with_api_token(api_token) do
      {:ok, user} ->
        login_via_api_token(conn, user)
      {:error, :token_invalid} ->
        conn
        |> put_rails_flash(:alert, "Invalid token. Make sure you pasted the URL correctly.")
        |> redirect(to: "/")
      {:error, :token_revoked} ->
        conn
        |> put_rails_flash(:alert, "This token has been revoked.")
        |> redirect(to: "/")
    end
  end

  def create(conn, _params) do
    login_token = get_session(conn, :login_token)
    conn = delete_session(conn, :login_token)

    case Users.verify_login_token(login_token) do
      {:ok, user} ->
        conn
        |> Users.log_in(user)
        |> put_rails_flash(:notice, "Welcome back!")
        |> redirect_to_profile
      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Invalid login link.")
        |> redirect(to: login_path(conn, :new))
      {:error, :token_expired} ->
        conn
        |> put_flash(:error, "This login link has expired, sorry.")
        |> redirect(to: login_path(conn, :new))
      {:error, :user_not_found} ->
        conn
        |> put_flash(:error, "This account has been removed.")
        |> redirect(to: login_path(conn, :new))
    end
  end

  defp login_via_api_token(conn, logging_user) do
    current_user = conn.assigns.current_user

    case {current_user, logging_user} do
      {nil, %User{email: nil}} ->
        conn
        |> Users.log_in(logging_user)
        |> put_rails_flash(:notice, "Welcome! Setting username and email will help you with logging in later.")
        |> redirect_to_edit_profile
      {nil, %User{}} ->
        conn
        |> Users.log_in(logging_user)
        |> put_rails_flash(:notice, "Welcome back!")
        |> redirect_to_profile
      {%User{id: id, email: nil}, %User{id: id}} ->
        conn
        |> put_rails_flash(:notice, "Setting username and email will help you with logging in later.")
        |> redirect_to_edit_profile
      {%User{email: nil}, %User{email: nil}} ->
        Users.merge!(current_user, logging_user)
        conn
        |> put_rails_flash(:notice, "Setting username and email will help you with logging in later.")
        |> redirect_to_edit_profile
      {%User{email: nil}, %User{}} ->
        Users.merge!(logging_user, current_user)
        conn
        |> Users.log_in(logging_user)
        |> put_rails_flash(:notice, "Recorder token has been added to your account.")
        |> redirect_to_profile
      {%User{}, %User{email: nil}} ->
        Users.merge!(current_user, logging_user)
        conn
        |> put_rails_flash(:notice, "Recorder token has been added to your account.")
        |> redirect_to_profile
      {%User{id: id}, %User{id: id}} ->
        conn
        |> put_rails_flash(:notice, "You're already logged in.")
        |> redirect_to_profile
      {%User{}, %User{}} ->
        conn
        |> put_rails_flash(:alert, "This recorder token belongs to a different user.")
        |> redirect_to_profile
        # TODO offer merging
    end
  end

  defp redirect_to_profile(conn) do
    path = case conn.assigns.current_user do
             %User{username: nil} -> "/username/new"
             %User{} = user -> profile_path(user)
           end

    redirect(conn, to: path)
  end

  defp redirect_to_edit_profile(conn) do
    redirect(conn, to: user_path(conn, :edit))
  end
end
