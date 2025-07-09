defmodule AsciinemaWeb.StreamControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory

  describe "show public stream as owner" do
    setup [:insert_public_stream, :authenticate_as_owner]

    test "via ID", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.id}", 404)
    end

    test "via public token", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.public_token}", 200)
    end
  end

  describe "show public stream as other user" do
    setup [:insert_public_stream, :authenticate_as_other]

    test "via ID", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.id}", 404)
    end

    test "via public token", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.public_token}", 200)
    end
  end

  describe "show public stream as guest" do
    setup [:insert_public_stream]

    test "via ID", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.id}", 404)
    end

    test "via public token", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.public_token}", 200)
    end
  end

  describe "show unlisted stream as owner" do
    setup [:insert_unlisted_stream, :authenticate_as_owner]

    test "via ID", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.id}", 404)
    end

    test "via public token", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.public_token}", 200)
    end
  end

  describe "show unlisted stream as other user" do
    setup [:insert_unlisted_stream, :authenticate_as_other]

    test "via ID", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.id}", 404)
    end

    test "via public token", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.public_token}", 200)
    end
  end

  describe "show unlisted stream as guest" do
    setup [:insert_unlisted_stream]

    test "via ID", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.id}", 404)
    end

    test "via public token", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.public_token}", 200)
    end
  end

  describe "show private stream as owner" do
    setup [:insert_private_stream, :authenticate_as_owner]

    test "via ID", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.id}", 404)
    end

    test "via public token", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.public_token}", 200)
    end
  end

  describe "show private stream as other user" do
    setup [:insert_private_stream, :authenticate_as_other]

    test "via ID", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.id}", 404)
    end

    test "via public token", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.public_token}", 403)
    end
  end

  describe "show private stream as guest" do
    setup [:insert_private_stream]

    test "via ID", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.id}", 404)
    end

    test "via public token", %{conn: conn, stream: stream} do
      test_html_response(conn, ~p"/s/#{stream.public_token}", 403)
    end
  end

  describe "show stream with streaming disabled" do
    test "returns 404", %{conn: conn} do
      user = insert(:user, streaming_enabled: false)
      stream = insert(:stream, user: user)

      conn_2 = get(conn, ~p"/s/#{stream}")

      assert html_response(conn_2, 404)
    end
  end

  describe "streaming instructions" do
    test "shows instructions only to owner", %{conn: conn} do
      user = insert(:user)
      stream = insert(:stream, user: user)

      conn_2 = get(conn, ~p"/s/#{stream}")
      refute html_response(conn_2, 200) =~ "asciinema stream -r"

      conn_2 = log_in(conn, insert(:user))
      conn_2 = get(conn_2, ~p"/s/#{stream}")
      refute html_response(conn_2, 200) =~ "asciinema stream -r"

      conn_2 = log_in(conn, user)
      conn_2 = get(conn_2, ~p"/s/#{stream}")
      assert html_response(conn_2, 200) =~ "asciinema stream -r"
    end
  end

  describe "editing" do
    setup ctx do
      user = insert(:user)

      Map.merge(ctx, %{
        user: user,
        stream: insert(:stream, user: user)
      })
    end

    test "requires logged in user", %{conn: conn, stream: stream} do
      conn = get(conn, ~p"/s/#{stream}/edit")

      assert redirected_to(conn, 302) == ~p"/login/new"
    end

    test "requires owner", %{conn: conn, stream: stream} do
      conn = log_in(conn, insert(:user))

      conn = get(conn, ~p"/s/#{stream}/edit")

      assert html_response(conn, 403) =~ "access"
    end

    test "displays form", %{conn: conn, stream: stream, user: user} do
      conn = log_in(conn, user)

      conn = get(conn, ~p"/s/#{stream}/edit")

      assert html_response(conn, 200) =~ "Save"
    end

    test "updates title", %{conn: conn, stream: stream, user: user} do
      conn = log_in(conn, user)

      attrs = %{stream: %{title: "Haha!"}}
      conn = put conn, ~p"/s/#{stream}", attrs

      location = List.first(get_resp_header(conn, "location"))
      assert flash(conn, :info) =~ ~r/updated/i
      assert response(conn, 302)

      conn = get(build_conn(), location)

      assert html_response(conn, 200) =~ "Haha!"
    end
  end

  describe "deleting" do
    setup ctx do
      user = insert(:user)

      Map.merge(ctx, %{
        user: user,
        stream: insert(:stream, user: user)
      })
    end

    test "requires logged in user", %{conn: conn, stream: stream} do
      conn = delete(conn, ~p"/s/#{stream}")

      assert redirected_to(conn, 302) == ~p"/login/new"
    end

    test "requires owner", %{conn: conn, stream: stream} do
      conn = log_in(conn, insert(:user))

      conn = delete(conn, ~p"/s/#{stream}")

      assert html_response(conn, 403) =~ "access"
    end

    test "deletes and redirects", %{conn: conn, stream: stream, user: user} do
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/s/#{stream}")

      assert flash(conn, :info) =~ ~r/deleted/i
      assert response(conn, 302)
    end
  end

  defp insert_public_stream(_context) do
    [stream: insert(:stream, visibility: :public)]
  end

  defp insert_unlisted_stream(_context) do
    [stream: insert(:stream, visibility: :unlisted)]
  end

  defp insert_private_stream(_context) do
    [stream: insert(:stream, visibility: :private)]
  end

  defp authenticate_as_owner(%{conn: conn, stream: stream}) do
    [conn: log_in(conn, stream.user)]
  end

  defp authenticate_as_other(%{conn: conn}) do
    [conn: log_in(conn, insert(:user))]
  end

  defp test_html_response(conn, url, 200) do
    conn_2 =
      conn
      |> put_req_header("accept", "*/*")
      |> get(url)

    assert html_response(conn_2, 200) =~ "createPlayer"

    conn_2 =
      conn
      |> put_req_header("accept", "text/html")
      |> get(url)

    assert html_response(conn_2, 200) =~ "createPlayer"
  end

  defp test_html_response(conn, url, status) when status >= 400 do
    conn = get(conn, url)

    assert html_response(conn, status)
  end
end
