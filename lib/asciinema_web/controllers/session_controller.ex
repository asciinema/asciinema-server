defmodule AsciinemaWeb.SessionController do
  use AsciinemaWeb, :controller

  def new(conn, %{"t" => login_token}) do
    conn
    |> put_session(:login_token, login_token)
    |> redirect(to: ~p"/session/new")
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, _params) do
    login_token = get_session(conn, :login_token)
    conn = delete_session(conn, :login_token)

    case Asciinema.verify_login_token(login_token) do
      {:ok, user} ->
        conn
        |> log_in(user)
        |> put_flash(:info, "Welcome back!")
        |> redirect_to_profile()

      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Invalid login link.")
        |> redirect(to: ~p"/login/new")

      {:error, :token_expired} ->
        conn
        |> put_flash(:error, "This login link has expired, sorry.")
        |> redirect(to: ~p"/login/new")

      {:error, :user_not_found} ->
        conn
        |> put_flash(:error, "This account has been removed.")
        |> redirect(to: ~p"/login/new")
    end
  end

  defp redirect_to_profile(conn) do
    user = conn.assigns.current_user

    if user.username do
      redirect_back_or(conn, to: profile_path(user))
    else
      redirect(conn, to: ~p"/username/new")
    end
  end

  def delete(conn, _params) do
    conn
    |> log_out()
    |> put_flash(:info, "See you later!")
    |> redirect(to: ~p"/")
  end
end
