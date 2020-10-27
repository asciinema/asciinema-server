defmodule AsciinemaWeb.ApiTokenController do
  use AsciinemaWeb, :controller
  alias Asciinema.Accounts
  alias Asciinema.Accounts.User

  plug :require_current_user

  def show(conn, %{"api_token" => token}) do
    case Accounts.get_or_create_api_token(token, conn.assigns.current_user) do
      {:ok, api_token} ->
        conn
        |> maybe_merge_users(api_token.user)
        |> redirect_to_profile

      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Invalid token. Make sure you pasted the URL correctly.")
        |> redirect(to: "/")

      {:error, :token_revoked} ->
        conn
        |> put_flash(:error, "This token has been revoked.")
        |> redirect(to: "/")
    end
  end

  def delete(conn, %{"id" => id}) do
    api_token = Accounts.get_api_token!(conn.assigns.current_user, id)
    Accounts.revoke_api_token!(api_token)

    conn
    |> put_flash(:info, "Token revoked.")
    |> redirect(to: Routes.user_path(conn, :edit))
  end

  defp maybe_merge_users(conn, api_token_user) do
    current_user = conn.assigns.current_user

    case {current_user, api_token_user} do
      # api token was just created
      {%User{id: id}, %User{id: id}} ->
        put_flash(conn, :info, "Recorder token has been added to your account.")

      # api token belongs to tmp user
      {%User{}, %User{email: nil, username: nil}} ->
        Asciinema.merge_accounts(api_token_user, current_user)
        put_flash(conn, :info, "Recorder token has been added to your account.")

      # api token belongs to other regular user
      {%User{}, %User{}} ->
        put_flash(conn, :error, "This recorder token belongs to a different user.")
    end
  end

  defp redirect_to_profile(conn) do
    path =
      case conn.assigns.current_user do
        %User{username: nil} -> "/username/new"
        %User{} = user -> profile_path(user)
      end

    redirect(conn, to: path)
  end
end
