defmodule AsciinemaWeb.UserController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Accounts, Streaming, Recordings}
  require Logger

  plug :require_current_user when action in [:edit, :update]

  def new(conn, %{"t" => sign_up_token}) do
    conn
    |> put_session(:sign_up_token, sign_up_token)
    |> redirect(to: ~p"/users/new")
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, _params) do
    token = get_session(conn, :sign_up_token)
    conn = delete_session(conn, :sign_up_token)

    case Asciinema.create_user_from_sign_up_token(token) do
      {:ok, user} ->
        conn
        |> log_in(user)
        |> put_flash(:info, "Welcome to asciinema!")
        |> redirect(to: ~p"/username/new")

      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Invalid sign-up link.")
        |> redirect(to: ~p"/login/new")

      {:error, :token_expired} ->
        conn
        |> put_flash(:error, "This sign-up link has expired, sorry.")
        |> redirect(to: ~p"/login/new")

      {:error, :email_taken} ->
        conn
        |> put_flash(:error, "You already signed up with this email.")
        |> redirect(to: ~p"/login/new")
    end
  end

  def show(conn, params) do
    if user = get_user(params) do
      do_show(conn, params, user)
    else
      {:error, :not_found}
    end
  end

  defp do_show(conn, params, user) do
    current_user = conn.assigns.current_user
    self = !!(current_user && current_user.id == user.id)

    filter =
      case self do
        true -> :all
        false -> :public
      end

    streams =
      case self do
        true -> Streaming.list_all_live_streams(user)
        false -> Streaming.list_public_live_streams(user)
      end

    asciicasts =
      Recordings.paginate_asciicasts(
        {user.id, filter},
        :date,
        params["page"],
        14
      )

    render(
      conn,
      "show.html",
      page_title: "#{user.username}'s profile",
      user: user,
      self: self,
      streams: streams,
      asciicasts: asciicasts
    )
  end

  defp get_user(%{"id" => id}) do
    if String.match?(id, ~r/^\d+$/) do
      Accounts.get_user(id)
    else
      Accounts.find_user_by_username(id)
    end
  end

  defp get_user(%{"username" => username}) do
    Accounts.find_user_by_username(username)
  end

  def edit(conn, _params) do
    user = conn.assigns.current_user
    changeset = Accounts.change_user(user)
    render_edit_form(conn, user, changeset)
  end

  def update(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Settings updated")
        |> redirect(to: ~p"/user/edit")

      {:error, %Ecto.Changeset{} = changeset} ->
        render_edit_form(conn, user, changeset)
    end
  end

  defp render_edit_form(conn, user, changeset) do
    api_tokens = Accounts.list_api_tokens(user)

    render(conn, "edit.html",
      changeset: changeset,
      api_tokens: api_tokens
    )
  end

  def delete(conn, %{"token" => token, "confirmed" => _}) do
    case Asciinema.delete_user(token) do
      :ok ->
        conn
        |> log_out()
        |> put_flash(:info, "Account deleted")
        |> redirect(to: ~p"/")

      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "Invalid account deletion token")
        |> redirect(to: ~p"/")
    end
  end

  def delete(conn, %{"t" => token}) do
    render(conn, :delete, token: token)
  end

  def delete(conn, _params) do
    user = conn.assigns.current_user
    address = user.email

    case Asciinema.send_account_deletion_email(user, AsciinemaWeb.UrlProvider) do
      :ok ->
        conn
        |> put_flash(:info, "Account removal initiated - check your inbox (#{address})")
        |> redirect(to: profile_path(conn))

      {:error, reason} ->
        Logger.warning("email delivery error: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Error sending email, please try again later")
        |> redirect(to: ~p"/user/edit")
    end
  end
end
