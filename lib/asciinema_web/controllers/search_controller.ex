defmodule AsciinemaWeb.SearchController do
  use AsciinemaWeb, :controller
  alias Asciinema.Recordings
  alias AsciinemaWeb.Authorization

  def show(conn, params) do
    q = params["q"] || ""

    page =
      Recordings.query()
      |> Recordings.search(q)
      |> Authorization.scope(:asciicasts, conn.assigns.current_user)
      |> Recordings.paginate(params["page"], 24, pagination_opts(conn))

    render(conn, "show.html", q: q, page: page)
  end
end
