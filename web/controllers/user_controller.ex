defmodule Asciinema.UserController do
  use Asciinema.Web, :controller
  alias Asciinema.Users

  def new(conn, %{"t" => signup_token}) do
    conn
    |> put_session(:signup_token, signup_token)
    |> redirect(to: users_path(conn, :new))
  end
  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, _params) do
    signup_token = get_session(conn, :signup_token)
    conn = delete_session(conn, :signup_token)

    case Users.verify_signup_token(signup_token) do
      {:ok, user} ->
        conn
        |> Users.log_in(user)
        |> put_rails_flash(:info, "Welcome to asciinema!")
        |> redirect(to: "/username/new")
      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Invalid sign-up link.")
        |> redirect(to: login_path(conn, :new))
      {:error, :token_expired} ->
        conn
        |> put_flash(:error, "This sign-up link has expired, sorry.")
        |> redirect(to: login_path(conn, :new))
      {:error, :email_taken} ->
        conn
        |> put_flash(:error, "You already signed up with this email.")
        |> redirect(to: login_path(conn, :new))
    end
  end
end
