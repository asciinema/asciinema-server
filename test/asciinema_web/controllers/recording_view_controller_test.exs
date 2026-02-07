defmodule AsciinemaWeb.RecordingViewControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory
  import Ecto.Query
  alias Asciinema.{Recordings, Repo}
  alias Asciinema.Recordings.AsciicastStats

  describe "create" do
    test "increments view count with valid token", %{conn: conn} do
      asciicast = insert(:asciicast)

      insert(:asciicast_stats,
        asciicast_id: asciicast.id,
        total_views: 5,
        popularity_dirty: false
      )

      token = Recordings.generate_view_count_token(asciicast.id)

      conn = with_csrf(conn)
      conn = post(conn, ~p"/a/#{asciicast}/views?token=#{token}")

      assert response(conn, 204)
      assert total_views(asciicast.id) == 6
    end

    test "sets cookie to prevent double counting", %{conn: conn} do
      asciicast = insert(:asciicast)

      insert(:asciicast_stats,
        asciicast_id: asciicast.id,
        total_views: 5,
        popularity_dirty: false
      )

      token = Recordings.generate_view_count_token(asciicast.id)

      conn = with_csrf(conn)
      conn = post(conn, ~p"/a/#{asciicast}/views?token=#{token}")

      assert response(conn, 204)
      assert conn.resp_cookies["a#{asciicast.id}"]
    end

    test "does not increment when cookie already present", %{conn: conn} do
      asciicast = insert(:asciicast)

      insert(:asciicast_stats,
        asciicast_id: asciicast.id,
        total_views: 5,
        popularity_dirty: false
      )

      token = Recordings.generate_view_count_token(asciicast.id)

      conn =
        conn
        |> with_csrf()
        |> put_req_cookie("a#{asciicast.id}", "1")
        |> post(~p"/a/#{asciicast}/views?token=#{token}")

      assert response(conn, 204)
      assert total_views(asciicast.id) == 5
    end

    test "returns 400 for invalid token", %{conn: conn} do
      asciicast = insert(:asciicast)

      insert(:asciicast_stats,
        asciicast_id: asciicast.id,
        total_views: 5,
        popularity_dirty: false
      )

      conn = with_csrf(conn)
      conn = post(conn, ~p"/a/#{asciicast}/views?token=invalid")

      assert response(conn, 400)
      assert total_views(asciicast.id) == 5
    end

    test "returns 400 when token ID doesn't match URL ID", %{conn: conn} do
      asciicast = insert(:asciicast)

      insert(:asciicast_stats,
        asciicast_id: asciicast.id,
        total_views: 5,
        popularity_dirty: false
      )

      other_asciicast = insert(:asciicast)
      token = Recordings.generate_view_count_token(other_asciicast.id)

      conn = with_csrf(conn)
      conn = post(conn, ~p"/a/#{asciicast}/views?token=#{token}")

      assert response(conn, 400)
      assert total_views(asciicast.id) == 5
    end

    test "returns 400 when asciicast doesn't exist", %{conn: conn} do
      token = Recordings.generate_view_count_token(999_999)

      conn = with_csrf(conn)
      conn = post(conn, ~p"/a/999999/views?token=#{token}")

      assert response(conn, 400)
    end

    test "returns 400 when token is missing", %{conn: conn} do
      asciicast = insert(:asciicast)

      insert(:asciicast_stats,
        asciicast_id: asciicast.id,
        total_views: 5,
        popularity_dirty: false
      )

      assert_error_sent 400, fn ->
        conn
        |> with_csrf()
        |> post(~p"/a/#{asciicast}/views")
      end

      assert total_views(asciicast.id) == 5
    end

    test "returns 403 when CSRF token is missing", %{conn: conn} do
      asciicast = insert(:asciicast)

      insert(:asciicast_stats,
        asciicast_id: asciicast.id,
        total_views: 5,
        popularity_dirty: false
      )

      token = Recordings.generate_view_count_token(asciicast.id)

      conn = require_csrf(conn)

      assert_error_sent 403, fn ->
        post(conn, ~p"/a/#{asciicast}/views?token=#{token}")
      end

      assert total_views(asciicast.id) == 5
    end
  end

  defp total_views(asciicast_id) do
    Repo.one(
      from(s in AsciicastStats,
        where: s.asciicast_id == ^asciicast_id,
        select: s.total_views
      )
    )
  end

  defp with_csrf(conn) do
    token = Plug.CSRFProtection.get_csrf_token()
    state = Plug.CSRFProtection.dump_state()

    conn
    |> require_csrf()
    |> put_session("_csrf_token", state)
    |> put_req_header("x-csrf-token", token)
  end

  defp require_csrf(conn) do
    conn
    |> Plug.Conn.put_private(:plug_skip_csrf_protection, false)
    |> Plug.Test.init_test_session(%{})
  end
end
