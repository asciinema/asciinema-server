defmodule Asciinema.SessionController do
  use Asciinema.Web, :controller
  import Asciinema.UserView, only: [profile_path: 1]
  alias Asciinema.{Auth, Users, User}

  def create(conn, %{"api_token" => api_token}) do
    case Users.authenticate(api_token) do
      {:ok, user} ->
        login(conn, user)
      {:error, :token_not_found} ->
        conn
        |> put_rails_flash(:alert, "Invalid token. Make sure you pasted the URL correctly.")
        |> redirect(to: "/")
      {:error, :token_revoked} ->
        conn
        |> put_rails_flash(:alert, "This token has been revoked.")
        |> redirect(to: "/")
    end
  end

  defp login(conn, logging_user) do
    case {conn.assigns.current_user, logging_user} do
      {nil, %User{email: nil}} ->
        conn
        |> Auth.login(logging_user)
        |> put_rails_flash(:notice, "Welcome! Setting username and email will help you with logging in later.")
        |> redirect_to_edit_profile
      {nil, %User{}} ->
        conn
        |> Auth.login(logging_user)
        |> put_rails_flash(:notice, "Welcome back!")
        |> redirect_to_profile
      {%User{id: id, email: nil}, %User{id: id}} ->
        conn
        |> put_rails_flash(:notice, "Setting username and email will help you with logging in later.")
        |> redirect_to_edit_profile
      {%User{email: nil}, %User{email: nil}} ->
        conn
        |> put_rails_flash(:notice, "WATCHA GONNA DO") # TODO
        |> redirect(to: "/")
      {%User{email: nil}, %User{}} ->
        conn
        |> put_rails_flash(:notice, "WATCHA GONNA DO") # TODO
        |> redirect(to: "/")
      {%User{} = u1, %User{email: nil} = u2} ->
        Users.merge!(u1, u2)
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

  defp put_rails_flash(conn, key, value) do
    put_session(conn, :flash, %{discard: [], flashes: %{key => value}})
  end

  defp redirect_to_profile(conn) do
    redirect(conn, to: profile_path(conn.assigns.current_user))
  end

  defp redirect_to_edit_profile(conn) do
    redirect(conn, to: user_path(conn, :edit))
  end
end
