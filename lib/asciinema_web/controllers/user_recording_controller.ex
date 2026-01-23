defmodule AsciinemaWeb.UserRecordingController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Accounts, Recordings}
  alias AsciinemaWeb.Authorization
  alias AsciinemaWeb.FallbackController

  plug :load_user

  def index(conn, params) do
    user = conn.assigns.user
    current_user = conn.assigns.current_user
    self = !!(current_user && current_user.id == user.id)

    asciicasts =
      [user_id: user.id]
      |> Recordings.query(:date)
      |> Authorization.scope(:asciicasts, current_user)
      |> Recordings.paginate(params["page"], 14)

    render(
      conn,
      "index.html",
      page_title: "#{user.username}'s profile",
      user: user,
      self: self,
      asciicasts: asciicasts
    )
  end

  defp load_user(conn, _opts) do
    if user = Accounts.find_user_by_username(conn.params["username"]) do
      assign(conn, :user, user)
    else
      conn
      |> FallbackController.call({:error, :not_found})
      |> halt()
    end
  end
end
