defmodule AsciinemaAdmin.RecordingControllerTest do
  use AsciinemaAdmin.ConnCase, async: true

  alias Asciinema.Recordings.Asciicast
  alias Asciinema.Repo

  describe "GET /admin/recordings" do
    test "lists recordings of every visibility", %{conn: conn} do
      insert(:asciicast, title: "alpha-record", visibility: :private)
      insert(:asciicast, title: "beta-record", visibility: :public)

      body = conn |> get(~p"/admin/recordings") |> html_response(200)

      assert body =~ "alpha-record"
      assert body =~ "beta-record"
    end

    test "filters by visibility", %{conn: conn} do
      insert(:asciicast, title: "private-one", visibility: :private)
      insert(:asciicast, title: "public-one", visibility: :public)

      body =
        conn |> get(~p"/admin/recordings?#{%{q: "visibility:private"}}") |> html_response(200)

      assert body =~ "private-one"
      refute body =~ "public-one"
    end

    test "filters by user", %{conn: conn} do
      user = insert(:user)
      mine = insert(:asciicast, user: user, title: "mine-only")
      _theirs = insert(:asciicast, title: "someone-else")

      body =
        conn
        |> get(~p"/admin/recordings?#{%{q: "user:#{user.id}"}}")
        |> html_response(200)

      assert body =~ "mine-only"
      refute body =~ "someone-else"
      assert body =~ ~s(/admin/recordings/#{mine.id})
    end

    test "reports invalid structured filters without running a partial query", %{conn: conn} do
      insert(:asciicast, title: "row-a")
      insert(:asciicast, title: "row-b")

      body =
        conn
        |> get(~p"/admin/recordings?#{%{q: "user:not-a-number visibility:publik"}}")
        |> html_response(200)

      assert body =~ "Query not run."
      assert body =~ "Invalid visibility"
      refute body =~ "row-a"
      refute body =~ "row-b"
    end
  end

  describe "GET /admin/recordings/:id" do
    test "renders the recording show page", %{conn: conn} do
      asciicast = insert(:asciicast, title: "abc-rec")

      body = conn |> get(~p"/admin/recordings/#{asciicast.id}") |> html_response(200)

      assert body =~ "abc-rec"
      assert body =~ "Overview"
      assert body =~ "Settings"
      assert body =~ "Metadata"
      assert body =~ "Actions ▾"
      assert body =~ ~s(id="player")
      assert body =~ "/admin/recordings/#{asciicast.id}/file"
      assert body =~ ~s(download="#{asciicast.user.username}-#{asciicast.id}.cast")
      assert body =~ "Delete recording ##{asciicast.id}?"
    end

    test "lists the captured env vars in Metadata", %{conn: conn} do
      asciicast = insert(:asciicast, env: %{"SHELL" => "/bin/zsh", "TERM" => "xterm-256color"})

      body = conn |> get(~p"/admin/recordings/#{asciicast.id}") |> html_response(200)

      assert body =~ ~r{<th><span class="truncate" title="SHELL">\s*SHELL\s*</span></th>}
      assert body =~ "/bin/zsh"
      assert body =~ ~r{<th><span class="truncate" title="TERM">\s*TERM\s*</span></th>}
    end

    test "supplies the original theme colors to the player", %{conn: conn} do
      asciicast =
        insert(:asciicast,
          term_theme_name: "original",
          term_theme_fg: "#aabbcc",
          term_theme_bg: "#112233",
          term_theme_palette: Enum.map_join(0..15, ":", fn i -> "#0000#{16 + i}" end)
        )

      body = conn |> get(~p"/admin/recordings/#{asciicast.id}") |> html_response(200)

      assert body =~ "--term-color-foreground: #aabbcc"
      assert body =~ "--term-color-background: #112233"
      assert body =~ "--term-color-0: #000016"
      assert body =~ "--term-color-15: #000031"
    end
  end

  describe "GET /admin/recordings/:id/edit and PUT" do
    test "updates the recording", %{conn: conn} do
      # The cols/rows overrides trigger snapshot regeneration, which reads the file
      asciicast = insert(:asciicast, title: "Old", compressed: false) |> with_file()

      conn =
        put(conn, ~p"/admin/recordings/#{asciicast.id}", %{
          "asciicast" => %{
            "title" => "New title",
            "visibility" => "public",
            "term_cols_override" => "100",
            "term_rows_override" => "30",
            "term_theme_name" => "dracula",
            "term_font_family" => "Fira Code",
            "speed" => "2.0",
            "idle_time_limit" => "1.5",
            "audio_url" => "https://example.com/audio.mp3"
          }
        })

      assert redirected_to(conn) == ~p"/admin/recordings/#{asciicast.id}"
      updated = Repo.get!(Asciicast, asciicast.id)
      assert updated.title == "New title"
      assert updated.visibility == :public
      assert updated.term_cols_override == 100
      assert updated.term_rows_override == 30
      assert updated.term_theme_name == "dracula"
      assert updated.term_font_family == "Fira Code"
      assert updated.speed == 2.0
      assert updated.idle_time_limit == 1.5
      assert updated.audio_url == "https://example.com/audio.mp3"
    end

    test "rerenders edit on validation failure (invalid visibility)", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :unlisted)

      conn =
        put(conn, ~p"/admin/recordings/#{asciicast.id}", %{
          "asciicast" => %{"visibility" => "nope"}
        })

      assert html_response(conn, 200) =~ "Edit recording"
      assert Repo.get!(Asciicast, asciicast.id).visibility == :unlisted
    end
  end

  describe "DELETE /admin/recordings/:id" do
    test "deletes the recording", %{conn: conn} do
      asciicast = insert(:asciicast)

      conn = delete(conn, ~p"/admin/recordings/#{asciicast.id}")

      assert redirected_to(conn) == ~p"/admin/recordings"
      refute Repo.get(Asciicast, asciicast.id)
    end
  end

  describe "POST /admin/recordings/:id/visibility" do
    test "changes visibility", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :unlisted)

      post(conn, ~p"/admin/recordings/#{asciicast.id}/visibility", %{"visibility" => "public"})

      assert Repo.get!(Asciicast, asciicast.id).visibility == :public
    end

    test "flashes error and does not crash on invalid visibility value", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :unlisted)

      conn =
        post(conn, ~p"/admin/recordings/#{asciicast.id}/visibility", %{
          "visibility" => "definitely-not-a-real-visibility"
        })

      assert redirected_to(conn) == ~p"/admin/recordings/#{asciicast.id}"
      assert flash(conn, :error) =~ "Could not"
      assert Repo.get!(Asciicast, asciicast.id).visibility == :unlisted
    end
  end

  describe "POST /admin/recordings/:id/featured" do
    test "toggles featured on", %{conn: conn} do
      asciicast = insert(:asciicast, featured: false)

      post(conn, ~p"/admin/recordings/#{asciicast.id}/featured", %{"featured" => "true"})

      assert Repo.get!(Asciicast, asciicast.id).featured == true
    end
  end

  describe "POST /admin/recordings/:id/unarchive" do
    test "clears archived_at and marks not archivable", %{conn: conn} do
      asciicast = insert(:asciicast, archived_at: ~U[2020-01-01 00:00:00Z], archivable: true)

      post(conn, ~p"/admin/recordings/#{asciicast.id}/unarchive", %{})

      updated = Repo.get!(Asciicast, asciicast.id)
      assert is_nil(updated.archived_at)
      assert updated.archivable == false
    end
  end

  describe "GET /admin/recordings/:id/file" do
    test "serves the cast file with the right content type, regardless of visibility",
         %{conn: conn} do
      asciicast =
        insert(:asciicast_v2, visibility: :private, compressed: false) |> with_file()

      conn = get(conn, ~p"/admin/recordings/#{asciicast.id}/file")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["application/x-asciicast"]
    end

    test "decompresses a compressed recording cached without a .zst suffix", %{conn: conn} do
      # mirrors remote/S3 storage: zstd-compressed bytes cached at a path without a .zst suffix
      asciicast = insert(:asciicast_v2, visibility: :private, compressed: true)
      zst_path = Asciinema.ZstdTestHelpers.zstd_fixture!("test/fixtures/welcome.cast")
      :ok = Asciinema.FileStore.put_file(asciicast.path, zst_path, "application/x-asciicast")

      conn = get(conn, ~p"/admin/recordings/#{asciicast.id}/file")

      assert response(conn, 200) == File.read!("test/fixtures/welcome.cast")
      assert get_resp_header(conn, "content-type") == ["application/x-asciicast"]
    end

    test "serves zstd directly when the client accepts it", %{conn: conn} do
      asciicast = insert(:asciicast_v2, visibility: :private, compressed: true)
      zst_path = Asciinema.ZstdTestHelpers.zstd_fixture!("test/fixtures/welcome.cast")
      :ok = Asciinema.FileStore.put_file(asciicast.path, zst_path, "application/x-asciicast")

      conn =
        conn
        |> put_req_header("accept-encoding", "gzip, deflate, br, zstd")
        |> get(~p"/admin/recordings/#{asciicast.id}/file")

      assert response(conn, 200) == File.read!(zst_path)
      assert get_resp_header(conn, "content-encoding") == ["zstd"]
    end

    test "returns 404 for missing id", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        get(conn, ~p"/admin/recordings/9999999/file")
      end
    end
  end

  describe "POST /admin/recordings/:id/archive" do
    test "stamps archived_at", %{conn: conn} do
      asciicast = insert(:asciicast, archived_at: nil)

      post(conn, ~p"/admin/recordings/#{asciicast.id}/archive", %{})

      assert %DateTime{} = Repo.get!(Asciicast, asciicast.id).archived_at
    end
  end
end
