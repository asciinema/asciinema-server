defmodule AsciinemaWeb.ApiTokenController do
  use AsciinemaWeb, :controller
  import AsciinemaWeb.UserView, only: [profile_path: 1]
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
        |> put_rails_flash(:alert, "Invalid token. Make sure you pasted the URL correctly.")
        |> redirect(to: "/")
      {:error, :token_revoked} ->
        conn
        |> put_rails_flash(:alert, "This token has been revoked.")
        |> redirect(to: "/")
    end
  end

  defp maybe_merge_users(conn, api_token_user) do
    current_user = conn.assigns.current_user

    case {current_user, api_token_user} do
      {%User{id: id}, %User{id: id}} -> # api token was just created
        put_rails_flash(conn, :notice, "Recorder token has been added to your account.")
      {%User{}, %User{email: nil, username: nil}} -> # api token belongs to tmp user
        Accounts.merge!(current_user, api_token_user)
        put_rails_flash(conn, :notice, "Recorder token has been added to your account.")
      {%User{}, %User{}} -> # api token belongs to other regular user
        put_rails_flash(conn, :alert, "This recorder token belongs to a different user.")
    end
  end

  defp redirect_to_profile(conn) do
    path = case conn.assigns.current_user do
             %User{username: nil} -> "/username/new"
             %User{} = user -> profile_path(user)
           end

    redirect(conn, to: path)
  end
end
