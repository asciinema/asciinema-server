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
        |> put_req_cookie("a#{asciicast.id}", "1")
        |> post(~p"/a/#{asciicast}/views?token=#{token}")

      assert response(conn, 204)
      assert total_views(asciicast.id) == 5
    end

    test "ignores invalid token", %{conn: conn} do
      asciicast = insert(:asciicast)

      insert(:asciicast_stats,
        asciicast_id: asciicast.id,
        total_views: 5,
        popularity_dirty: false
      )

      conn = post(conn, ~p"/a/#{asciicast}/views?token=invalid")

      assert response(conn, 204)
      assert total_views(asciicast.id) == 5
    end

    test "ignores token whose ID doesn't match the URL ID", %{conn: conn} do
      asciicast = insert(:asciicast)

      insert(:asciicast_stats,
        asciicast_id: asciicast.id,
        total_views: 5,
        popularity_dirty: false
      )

      other_asciicast = insert(:asciicast)
      token = Recordings.generate_view_count_token(other_asciicast.id)

      conn = post(conn, ~p"/a/#{asciicast}/views?token=#{token}")

      assert response(conn, 204)
      assert total_views(asciicast.id) == 5
    end

    test "ignores token for a non-existent asciicast", %{conn: conn} do
      token = Recordings.generate_view_count_token(999_999)

      conn = post(conn, ~p"/a/999999/views?token=#{token}")

      assert response(conn, 204)
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
end
