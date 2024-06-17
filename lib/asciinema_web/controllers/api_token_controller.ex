defmodule AsciinemaWeb.ApiTokenController do
  use AsciinemaWeb, :controller
  alias Asciinema.Accounts
  alias Asciinema.Accounts.User

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
    api_token = Accounts.get_api_token!(conn.assigns.current_user, id)
    Accounts.revoke_api_token!(api_token)

    conn
    |> put_flash(:info, "CLI authentication revoked")
    |> redirect(to: ~p"/user/edit")
  end

  defp redirect_to_profile(conn) do
    path =
      case conn.assigns.current_user do
        %User{username: nil} -> ~p"/username/new"
        %User{} = user -> profile_path(user)
      end

    redirect(conn, to: path)
  end
end
