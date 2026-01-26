defmodule AsciinemaWeb.UserStreamController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Accounts, Streaming}
  alias AsciinemaWeb.Authorization
  alias AsciinemaWeb.FallbackController

  plug :load_user

  def live(conn, params) do
    user = conn.assigns.user
    current_user = conn.assigns.current_user
    self = !!(current_user && current_user.id == user.id)

    streams =
      [:live, user_id: user.id]
      |> Streaming.query(:recently_started)
      |> Authorization.scope(:streams, current_user)
      |> Streaming.paginate(params["page"], 14)

    render(
      conn,
      "live.html",
      page_title: "#{user.username}'s live streams",
      user: user,
      self: self,
      streams: streams
    )
  end

  def upcoming(conn, params) do
    user = conn.assigns.user
    current_user = conn.assigns.current_user
    self = !!(current_user && current_user.id == user.id)

    streams =
      [{:user_id, user.id}, :upcoming]
      |> Streaming.query(:soonest)
      |> Authorization.scope(:streams, current_user)
      |> Streaming.paginate(params["page"], 14)

    render(
      conn,
      "upcoming.html",
      page_title: "#{user.username}'s upcoming streams",
      user: user,
      self: self,
      streams: streams
    )
  end

  defp load_user(conn, _opts) do
    if user = Accounts.find_user_by_profile_id(conn.params["username"]) do
      assign(conn, :user, user)
    else
      conn
      |> FallbackController.call({:error, :not_found})
      |> halt()
    end
  end
end
