defmodule AsciinemaWeb.SessionController do
  use AsciinemaWeb, :controller

  plug :redirect_current_user when action in [:new, :create]

  def new(conn, %{"t" => login_token}) do
    render(conn, "new.html", login_token: login_token)
  end

  def new(conn, _params) do
    redirect(conn, to: ~p"/login/new")
  end

  def create(conn, %{"t" => login_token} = params) do
    timezone = params["timezone"]

    case Asciinema.confirm_login(login_token, timezone) do
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

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Invalid login link.")
    |> redirect(to: ~p"/login/new")
  end

  defp redirect_to_profile(conn) do
    user = conn.assigns.current_user

    if user.username do
      redirect_back_or(conn, to: ~p"/~#{user}")
    else
      redirect(conn, to: ~p"/username/new")
    end
  end

  defp redirect_current_user(
         %{assigns: %{current_user: %Asciinema.Accounts.User{} = user}} = conn,
         _
       ) do
    conn
    |> put_flash(:info, "You're already logged in.")
    |> redirect(to: current_user_path(user))
    |> halt()
  end

  defp redirect_current_user(conn, _), do: conn

  defp current_user_path(%{username: username} = user) when is_binary(username), do: ~p"/~#{user}"
  defp current_user_path(_user), do: ~p"/username/new"

  def delete(conn, _params) do
    conn
    |> log_out()
    |> put_flash(:info, "See you later!")
    |> redirect(to: ~p"/")
  end
end
