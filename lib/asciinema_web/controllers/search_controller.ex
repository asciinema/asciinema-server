defmodule AsciinemaWeb.SearchController do
  use AsciinemaWeb, :controller
  alias Asciinema.Recordings
  alias Asciinema.Recordings.Query, as: RecordingQuery

  def show(conn, params) do
    q = params["q"] || ""

    page =
      %RecordingQuery{
        scope: {:listing_for, conn.assigns.current_user},
        filters: [{:full_text, {:search, q}}],
        sort: {:rank, :desc}
      }
      |> Recordings.search_paginate(params["page"], 24, pagination_opts(conn))

    render(conn, "show.html", q: q, page: page)
  end
end
