defmodule AsciinemaWeb.SessionController do
  use AsciinemaWeb, :controller
  alias Asciinema.Accounts
  alias AsciinemaWeb.Auth
  alias Asciinema.Accounts.User

  def new(conn, %{"t" => login_token}) do
    conn
    |> put_session(:login_token, login_token)
    |> redirect(to: Routes.session_path(conn, :new))
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, _params) do
    login_token = get_session(conn, :login_token)
    conn = delete_session(conn, :login_token)

    case Accounts.verify_login_token(login_token) do
      {:ok, user} ->
        conn
        |> Auth.log_in(user)
        |> put_flash(:info, "Welcome back!")
        |> redirect_to_profile

      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Invalid login link.")
        |> redirect(to: Routes.login_path(conn, :new))

      {:error, :token_expired} ->
        conn
        |> put_flash(:error, "This login link has expired, sorry.")
        |> redirect(to: Routes.login_path(conn, :new))

      {:error, :user_not_found} ->
        conn
        |> put_flash(:error, "This account has been removed.")
        |> redirect(to: Routes.login_path(conn, :new))
    end
  end

  defp redirect_to_profile(conn) do
    case conn.assigns.current_user do
      %User{username: nil} ->
        redirect(conn, to: Routes.username_path(conn, :new))
      %User{} = user ->
        redirect_back_or(conn, to: profile_path(user))
    end
  end

  def delete(conn, _params) do
    conn
    |> Auth.log_out()
    |> put_flash(:info, "See you later!")
    |> redirect(to: Routes.home_path(conn, :show))
  end
end
