defmodule AsciinemaWeb.RecordingViewControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory
  alias Asciinema.{Recordings, Repo}

  describe "create" do
    test "increments view count with valid token", %{conn: conn} do
      asciicast = insert(:asciicast, views_count: 5)
      token = Recordings.generate_view_count_token(asciicast.id)

      conn = with_csrf(conn)
      conn = post(conn, ~p"/a/#{asciicast}/views?token=#{token}")

      assert response(conn, 204)
      assert Repo.reload!(asciicast).views_count == 6
    end

    test "sets cookie to prevent double counting", %{conn: conn} do
      asciicast = insert(:asciicast, views_count: 5)
      token = Recordings.generate_view_count_token(asciicast.id)

      conn = with_csrf(conn)
      conn = post(conn, ~p"/a/#{asciicast}/views?token=#{token}")

      assert response(conn, 204)
      assert conn.resp_cookies["a#{asciicast.id}"]
    end

    test "does not increment when cookie already present", %{conn: conn} do
      asciicast = insert(:asciicast, views_count: 5)
      token = Recordings.generate_view_count_token(asciicast.id)

      conn =
        conn
        |> with_csrf()
        |> put_req_cookie("a#{asciicast.id}", "1")
        |> post(~p"/a/#{asciicast}/views?token=#{token}")

      assert response(conn, 204)
      assert Repo.reload!(asciicast).views_count == 5
    end

    test "returns 400 for invalid token", %{conn: conn} do
      asciicast = insert(:asciicast, views_count: 5)

      conn = with_csrf(conn)
      conn = post(conn, ~p"/a/#{asciicast}/views?token=invalid")

      assert response(conn, 400)
      assert Repo.reload!(asciicast).views_count == 5
    end

    test "returns 400 when token ID doesn't match URL ID", %{conn: conn} do
      asciicast = insert(:asciicast, views_count: 5)
      other_asciicast = insert(:asciicast)
      token = Recordings.generate_view_count_token(other_asciicast.id)

      conn = with_csrf(conn)
      conn = post(conn, ~p"/a/#{asciicast}/views?token=#{token}")

      assert response(conn, 400)
      assert Repo.reload!(asciicast).views_count == 5
    end

    test "returns 400 when asciicast doesn't exist", %{conn: conn} do
      token = Recordings.generate_view_count_token(999_999)

      conn = with_csrf(conn)
      conn = post(conn, ~p"/a/999999/views?token=#{token}")

      assert response(conn, 400)
    end

    test "returns 400 when token is missing", %{conn: conn} do
      asciicast = insert(:asciicast, views_count: 5)

      assert_error_sent 400, fn ->
        conn
        |> with_csrf()
        |> post(~p"/a/#{asciicast}/views")
      end

      assert Repo.reload!(asciicast).views_count == 5
    end

    test "returns 403 when CSRF token is missing", %{conn: conn} do
      asciicast = insert(:asciicast, views_count: 5)
      token = Recordings.generate_view_count_token(asciicast.id)

      conn = require_csrf(conn)

      assert_error_sent 403, fn ->
        post(conn, ~p"/a/#{asciicast}/views?token=#{token}")
      end

      assert Repo.reload!(asciicast).views_count == 5
    end
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
