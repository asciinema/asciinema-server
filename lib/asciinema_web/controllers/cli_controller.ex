defmodule AsciinemaWeb.CliController do
  use AsciinemaWeb, :controller

  plug :require_current_user

  def register(conn, %{"install_id" => install_id}) do
    case Asciinema.register_cli(conn.assigns.current_user, install_id) do
      :ok ->
        conn
        |> put_flash(:info, "CLI successfully authenticated with your account")
        |> redirect_back_or(to: next_path(conn))

      {:error, :token_taken} ->
        conn
        |> put_flash(:error, "This CLI has been authenticated with a different user account")
        |> redirect_back_or(to: next_path(conn))

      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Invalid installation ID - make sure to paste the URL correctly")
        |> redirect_back_or(to: ~p"/")

      {:error, :cli_revoked} ->
        conn
        |> put_flash(:error, "This CLI authentication has been revoked")
        |> redirect_back_or(to: ~p"/")
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

  defp next_path(conn) do
    user = conn.assigns.current_user

    if user.username do
      profile_path(user)
    else
      ~p"/username/new"
    end
  end
end
