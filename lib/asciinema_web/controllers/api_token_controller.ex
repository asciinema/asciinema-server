defmodule AsciinemaWeb.ApiTokenController do
  use AsciinemaWeb, :controller

  plug :require_current_user

  def register(conn, %{"api_token" => token}) do
    case Asciinema.register_cli(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "CLI successfully authenticated with your account")
        |> redirect_to_profile()

      {:error, :token_taken} ->
        conn
        |> put_flash(:error, "This CLI has been authenticated with a different user account")
        |> redirect_to_profile()

      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Invalid installation ID - make sure to paste the URL correctly")
        |> redirect(to: ~p"/")

      {:error, :token_revoked} ->
        conn
        |> put_flash(:error, "This CLI authentication has been revoked")
        |> redirect(to: ~p"/")
    end
  end

  def delete(conn, %{"id" => id}) do
    case Asciinema.revoke_cli(conn.assigns.current_user, id) do
      :ok ->
        conn
        |> put_flash(:info, "CLI authentication revoked")
        |> redirect(to: ~p"/user/edit")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "CLI not found")
        |> redirect(to: ~p"/user/edit")
    end
  end

  defp redirect_to_profile(conn) do
    user = conn.assigns.current_user

    if user.username do
      redirect(conn, to: profile_path(user))
    else
      redirect(conn, to: ~p"/username/new")
    end
  end
end
