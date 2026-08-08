defmodule AsciinemaWeb.StreamStatusLiveTest do
  use AsciinemaWeb.ConnCase, async: true

  import Asciinema.Factory
  import Phoenix.LiveViewTest

  alias AsciinemaWeb.StreamStatusLive

  test "renders the status of an existing stream", %{conn: conn} do
    stream = insert(:stream)

    {:ok, _view, html} =
      live_isolated(conn, StreamStatusLive, session: %{"stream_id" => stream.id})

    assert html =~ "status-line"
  end

  test "renders when the stream no longer exists", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, StreamStatusLive, session: %{"stream_id" => -1})

    assert html =~ "Stream hasn&#39;t started"
  end
end
