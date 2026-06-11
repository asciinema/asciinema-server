defmodule AsciinemaAdmin.StreamControllerTest do
  use AsciinemaAdmin.ConnCase, async: true

  alias Asciinema.Repo
  alias Asciinema.Streaming.Stream

  describe "GET /admin/streams" do
    test "lists streams of every visibility", %{conn: conn} do
      insert(:stream, title: "alpha-stream", visibility: :private)
      insert(:stream, title: "beta-stream", visibility: :public)

      body = conn |> get(~p"/admin/streams") |> html_response(200)

      assert body =~ "alpha-stream"
      assert body =~ "beta-stream"
    end

    test "filters by live", %{conn: conn} do
      insert(:stream, title: "i-am-live", live: true)
      insert(:stream, title: "im-offline", live: false)

      body = conn |> get(~p"/admin/streams?#{%{q: "live:yes"}}") |> html_response(200)

      assert body =~ "i-am-live"
      refute body =~ "im-offline"
    end

    test "filters by user", %{conn: conn} do
      user = insert(:user)
      mine = insert(:stream, user: user, title: "mine-stream")
      _theirs = insert(:stream, title: "other-stream")

      body =
        conn
        |> get(~p"/admin/streams?#{%{q: "user:#{user.id}"}}")
        |> html_response(200)

      assert body =~ "mine-stream"
      refute body =~ "other-stream"
      assert body =~ ~s(/admin/streams/#{mine.id})
    end
  end

  describe "GET /admin/streams/:id" do
    test "renders the stream show page with player and recordings list", %{conn: conn} do
      stream = insert(:stream, title: "demo-stream")
      asciicast = insert(:asciicast, stream_id: stream.id, title: "recorded-from-stream")
      _unrelated = insert(:asciicast, title: "no-stream-link")

      body = conn |> get(~p"/admin/streams/#{stream.id}") |> html_response(200)

      assert body =~ "demo-stream"
      assert body =~ "producer token"
      assert body =~ ~s(id="player")
      assert body =~ "/ws/s/#{stream.public_token}"
      assert body =~ "Recordings from this stream"
      assert body =~ "recorded-from-stream"
      refute body =~ "no-stream-link"
      assert body =~ "/admin/recordings/#{asciicast.id}"
      assert body =~ "Delete stream ##{stream.id}?"
    end

    test "shows the configured theme in Terminal and session terminal facts in Last session",
         %{conn: conn} do
      stream =
        insert(:stream,
          term_theme_name: "nord",
          term_cols: 120,
          term_rows: 40,
          term_type: "xterm-256color",
          term_theme_fg: "#aabbcc",
          term_theme_bg: "#112233",
          term_theme_palette: Enum.map_join(0..15, ":", fn i -> "#0000#{16 + i}" end),
          env: %{"SHELL" => "/bin/fish"}
        )

      body = conn |> get(~p"/admin/streams/#{stream.id}") |> html_response(200)

      # Settings card: the configured named theme
      assert body =~ "Nord"
      # Last session card: captured env vars
      assert body =~ ~r{<th><span class="truncate" title="SHELL">\s*SHELL\s*</span></th>}
      assert body =~ "/bin/fish"
      # Last session card: captured session facts
      assert body =~ "terminal cols × rows"
      assert body =~ "120 × 40"
      assert body =~ "xterm-256color"
      assert body =~ "terminal original theme"
      # captured palette renders as a strip (palette color 0)
      assert body =~ "#000016"
    end
  end

  describe "POST /admin/streams/:id/visibility" do
    test "changes visibility", %{conn: conn} do
      stream = insert(:stream, visibility: :unlisted)

      post(conn, ~p"/admin/streams/#{stream.id}/visibility", %{"visibility" => "public"})

      assert Repo.get!(Stream, stream.id).visibility == :public
    end

    test "flashes error and does not crash on invalid visibility value", %{conn: conn} do
      stream = insert(:stream, visibility: :unlisted)

      conn =
        post(conn, ~p"/admin/streams/#{stream.id}/visibility", %{"visibility" => "bogus"})

      assert redirected_to(conn) == ~p"/admin/streams/#{stream.id}"
      assert flash(conn, :error) =~ "Could not"
      assert Repo.get!(Stream, stream.id).visibility == :unlisted
    end
  end

  describe "GET /admin/streams/:id/edit and PUT" do
    test "updates the stream", %{conn: conn} do
      stream = insert(:stream, title: "Old")

      conn =
        put(conn, ~p"/admin/streams/#{stream.id}", %{
          "stream" => %{
            "title" => "New title",
            "term_theme_name" => "nord",
            "term_font_family" => "JetBrains Mono",
            "buffer_time" => "2.5",
            "audio_url" => "https://example.com/stream.m3u8"
          }
        })

      assert redirected_to(conn) == ~p"/admin/streams/#{stream.id}"
      updated = Repo.get!(Stream, stream.id)
      assert updated.title == "New title"
      assert updated.term_theme_name == "nord"
      assert updated.term_font_family == "JetBrains Mono"
      assert updated.buffer_time == 2.5
      assert updated.audio_url == "https://example.com/stream.m3u8"
    end

    test "renders the edit form", %{conn: conn} do
      stream = insert(:stream, title: "edit-me")

      body = conn |> get(~p"/admin/streams/#{stream.id}/edit") |> html_response(200)

      assert body =~ "Edit stream ##{stream.id}"
      assert body =~ "Account default"
    end

    test "rerenders edit form on validation failure (invalid cron schedule)",
         %{conn: conn} do
      stream = insert(:stream, title: "Keep me", schedule: nil)

      conn =
        put(conn, ~p"/admin/streams/#{stream.id}", %{
          "stream" => %{"schedule" => "this is not a cron expression"}
        })

      assert html_response(conn, 200) =~ "Edit stream"
      assert Repo.get!(Stream, stream.id).title == "Keep me"
      assert Repo.get!(Stream, stream.id).schedule == nil
    end
  end

  describe "DELETE /admin/streams/:id" do
    test "deletes the stream", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/admin/streams/#{stream.id}")

      assert redirected_to(conn) == ~p"/admin/streams"
      refute Repo.get(Stream, stream.id)
    end
  end

  describe "POST /admin/streams/:id/disconnect" do
    test "flashes 'not running' when no GenServer is registered", %{conn: conn} do
      stream = insert(:stream)

      conn = post(conn, ~p"/admin/streams/#{stream.id}/disconnect", %{})

      assert redirected_to(conn) == ~p"/admin/streams/#{stream.id}"
      assert flash(conn, :info) =~ "not running"
    end
  end
end
