defmodule AsciinemaWeb.EmailController do
  use AsciinemaWeb, :controller

  plug :require_current_user

  def update(conn, %{"user" => %{"email" => email}}) do
    case Asciinema.initiate_email_change(
           conn.assigns.current_user,
           email,
           AsciinemaWeb.UrlProvider
         ) do
      {:ok, :changed} ->
        redirect(conn, to: ~p"/user/edit")

      {:ok, {:pending, email}} ->
        redirect(conn, to: ~p"/user/edit?ec-status=pending&ec-addr=#{email}")

      {:error, reason} ->
        redirect(conn, to: ~p"/user/edit?ec-status=#{reason}")
    end
  end

  def update(conn, %{"t" => token}) do
    case Asciinema.finalize_email_change(conn.assigns.current_user, token) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email address has been changed")
        |> redirect(to: ~p"/user/edit")

      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "Email not updated - invalid or expired link")
        |> redirect(to: ~p"/user/edit")

      {:error, :email_taken} ->
        conn
        |> put_flash(:error, "Email not updated - this address belongs to another account")
        |> redirect(to: ~p"/user/edit")

      {:error, :user_mismatch} ->
        conn
        |> put_flash(:error, "Email not updated - the link was generated for another account")
        |> redirect(to: ~p"/user/edit")
    end
  end

  def update(conn, _params) do
    conn
    |> put_flash(:error, "Invalid or expired link")
    |> redirect(to: ~p"/user/edit")
  end
end
