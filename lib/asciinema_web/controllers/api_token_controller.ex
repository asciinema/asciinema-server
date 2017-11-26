defmodule AsciinemaWeb.ApiTokenController do
  use AsciinemaWeb, :controller
  import AsciinemaWeb.UserView, only: [profile_path: 1]
  alias Asciinema.Accounts
  alias AsciinemaWeb.Auth
  alias Asciinema.Accounts.User

  def create(conn, %{"api_token" => api_token}) do
    case Accounts.get_user_with_api_token(api_token) do
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

  defp login_via_api_token(conn, logging_user) do
    current_user = conn.assigns.current_user

    case {current_user, logging_user} do
      {nil, %User{email: nil}} ->
        conn
        |> Auth.log_in(logging_user)
        |> put_rails_flash(:notice, "Welcome! Setting username and email will help you with logging in later.")
        |> redirect_to_edit_profile
      {nil, %User{}} ->
        conn
        |> Auth.log_in(logging_user)
        |> put_rails_flash(:notice, "Welcome back!")
        |> redirect_to_profile
      {%User{id: id, email: nil}, %User{id: id}} ->
        conn
        |> put_rails_flash(:notice, "Setting username and email will help you with logging in later.")
        |> redirect_to_edit_profile
      {%User{email: nil}, %User{email: nil}} ->
        Accounts.merge!(current_user, logging_user)
        conn
        |> put_rails_flash(:notice, "Setting username and email will help you with logging in later.")
        |> redirect_to_edit_profile
      {%User{email: nil}, %User{}} ->
        Accounts.merge!(logging_user, current_user)
        conn
        |> Auth.log_in(logging_user)
        |> put_rails_flash(:notice, "Recorder token has been added to your account.")
        |> redirect_to_profile
      {%User{}, %User{email: nil}} ->
        Accounts.merge!(current_user, logging_user)
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
