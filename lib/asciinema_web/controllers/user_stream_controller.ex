defmodule AsciinemaWeb.UserStreamController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Accounts, Streaming}
  alias Asciinema.Streaming.Query, as: StreamQuery
  alias AsciinemaWeb.FallbackController

  plug :load_user

  def live(conn, params) do
    user = conn.assigns.user
    current_user = conn.assigns.current_user
    self = !!(current_user && current_user.id == user.id)

    streams =
      %StreamQuery{
        scope: {:listing_for, current_user},
        filters: [:live, {:user, user}],
        sort: :recently_started
      }
      |> Streaming.paginate(params["page"], 14, pagination_opts(conn, owner_id: user.id))

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
      %StreamQuery{
        scope: {:listing_for, current_user},
        filters: [{:user, user}, :upcoming],
        sort: :soonest
      }
      |> Streaming.paginate(params["page"], 14, pagination_opts(conn, owner_id: user.id))

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
