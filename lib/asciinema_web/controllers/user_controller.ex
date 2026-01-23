defmodule AsciinemaWeb.UserController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Accounts, Streaming, Recordings}
  alias AsciinemaWeb.Authorization
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

  def create(conn, params) do
    token = get_session(conn, :sign_up_token)
    conn = delete_session(conn, :sign_up_token)
    timezone = params["timezone"]

    case Asciinema.confirm_sign_up(token, timezone) do
      {:ok, user} ->
        conn
        |> log_in(user)
        |> put_flash(:info, "Welcome to asciinema!")
        |> redirect_back_then(to: ~p"/username/new")

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
      do_show(conn, user)
    else
      {:error, :not_found}
    end
  end

  defp do_show(conn, user) do
    current_user = conn.assigns.current_user
    self = !!(current_user && current_user.id == user.id)
    live_streams = fetch_live_streams(user, current_user)
    upcoming_streams = fetch_upcoming_streams(user, current_user)
    asciicasts = fetch_recent_asciicasts(user, current_user, [live_streams, upcoming_streams])

    render(
      conn,
      "show.html",
      page_title: "#{user.username}'s profile",
      user: user,
      self: self,
      live_streams: live_streams,
      upcoming_streams: upcoming_streams,
      asciicasts: asciicasts
    )
  end

  defp fetch_live_streams(%{streaming_enabled: true} = user, current_user) do
    [:live, user_id: user.id]
    |> Streaming.query()
    |> Authorization.scope(:streams, current_user)
    |> list_streams(2)
  end

  defp fetch_live_streams(%{streaming_enabled: false}, _current_user), do: :disabled

  defp fetch_upcoming_streams(%{streaming_enabled: true} = user, current_user) do
    [:upcoming, user_id: user.id]
    |> Streaming.query(:soonest)
    |> Authorization.scope(:streams, current_user)
    |> list_streams(2)
  end

  defp fetch_upcoming_streams(%{streaming_enabled: false}, _current_user), do: :disabled

  defp fetch_recent_asciicasts(user, current_user, earlier_sections) do
    used_rows =
      Enum.reduce(earlier_sections, 0, fn section, acc ->
        case section do
          :disabled -> acc
          %{items: []} -> acc
          %{items: _} -> acc + 1
        end
      end)

    limit = (4 - used_rows) * 2

    [user_id: user.id]
    |> Recordings.query(:date)
    |> Authorization.scope(:asciicasts, current_user)
    |> list_asciicasts(limit)
  end

  defp list_streams(query, limit) do
    items = Streaming.list(query, limit + 1)

    %{
      items: Enum.take(items, limit),
      has_more: length(items) > limit
    }
  end

  defp list_asciicasts(query, limit) do
    items = Recordings.list(query, limit + 1)

    %{
      items: Enum.take(items, limit),
      has_more: length(items) > limit
    }
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

    case Asciinema.update_user(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Settings updated")
        |> redirect(to: ~p"/user/edit")

      {:error, %Ecto.Changeset{} = changeset} ->
        render_edit_form(conn, user, changeset)
    end
  end

  defp render_edit_form(conn, user, changeset) do
    clis = Accounts.list_clis(user)

    render(conn, "edit.html",
      changeset: changeset,
      timezones: Tzdata.canonical_zone_list(),
      streaming_enabled: user.streaming_enabled,
      stream_recording_mode: Streaming.recording_mode(),
      clis: clis
    )
  end

  def delete(conn, %{"token" => token, "confirmed" => _}) do
    case Asciinema.confirm_account_deletion(token) do
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

    case Asciinema.initiate_account_deletion(user, AsciinemaWeb.UrlProvider) do
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
