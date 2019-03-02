defmodule AsciinemaWeb.LoginController do
  use AsciinemaWeb, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"login" => %{"email" => email_or_username}}) do
    email_or_username = String.trim(email_or_username)

    result =
      Asciinema.send_login_email(
        email_or_username,
        &AsciinemaWeb.signup_url/1,
        &AsciinemaWeb.login_url/1
      )

    case result do
      :ok ->
        redirect(conn, to: login_path(conn, :sent))

      {:error, :user_not_found} ->
        render(conn, "new.html", error: "No user found for given username.")

      {:error, :email_invalid} ->
        render(conn, "new.html", error: "This doesn't look like a correct email address.")

      {:error, :email_missing} ->
        redirect(conn, to: login_path(conn, :sent))
    end
  end

  def sent(conn, _params) do
    render(conn, "sent.html")
  end
end
