defmodule Asciinema.LiveStreamControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory
  alias Asciinema.Authorization

  describe "show" do
    test "HTML, private stream via ID", %{conn: conn} do
      stream = insert(:live_stream, private: true)

      conn_2 = get(conn, "/s/#{stream.id}")

      assert html_response(conn_2, 404)
    end

    test "HTML, private stream via secret token", %{conn: conn} do
      stream = insert(:live_stream, private: true)

      conn_2 = get(conn, "/s/#{stream.secret_token}")

      assert html_response(conn_2, 200) =~ "createPlayer"
      assert response_content_type(conn_2, :html)
    end

    test "HTML, public stream via ID", %{conn: conn} do
      stream = insert(:live_stream, private: false)

      conn_2 = get(conn, "/s/#{stream.id}")

      assert html_response(conn_2, 200) =~ "createPlayer"
      assert response_content_type(conn_2, :html)
    end

    test "HTML, public stream via secret token", %{conn: conn} do
      stream = insert(:live_stream, private: false)

      conn_2 = get(conn, "/s/#{stream.secret_token}")

      assert html_response(conn_2, 200) =~ "createPlayer"
      assert response_content_type(conn_2, :html)
    end

    test "HTML, streaming instructions", %{conn: conn} do
      user = insert(:user)
      stream = insert(:live_stream, user: user)

      conn_2 = get(conn, "/s/#{stream.secret_token}")
      refute html_response(conn_2, 200) =~ stream.producer_token

      conn_2 = log_in(conn, insert(:user))
      conn_2 = get(conn_2, "/s/#{stream.secret_token}")
      refute html_response(conn_2, 200) =~ stream.producer_token

      conn_2 = log_in(conn, user)
      conn_2 = get(conn_2, "/s/#{stream.secret_token}")
      assert html_response(conn_2, 200) =~ stream.producer_token
    end
  end

  describe "editing" do
    setup ctx do
      user = insert(:user)

      Map.merge(ctx, %{
        user: user,
        stream: insert(:live_stream, user: user)
      })
    end

    test "requires logged in user", %{conn: conn, stream: stream} do
      conn = get(conn, ~p"/s/#{stream}/edit")

      assert redirected_to(conn, 302) == "/login/new"
    end

    test "requires owner", %{conn: conn, stream: stream} do
      conn = log_in(conn, insert(:user))

      assert_raise(Authorization.ForbiddenError, fn ->
        get(conn, ~p"/s/#{stream}/edit")
      end)
    end

    test "displays form", %{conn: conn, stream: stream, user: user} do
      conn = log_in(conn, user)

      conn = get(conn, ~p"/s/#{stream}/edit")

      assert html_response(conn, 200) =~ "Save"
    end

    test "updates title", %{conn: conn, stream: stream, user: user} do
      conn = log_in(conn, user)

      attrs = %{live_stream: %{title: "Haha!"}}
      conn = put conn, ~p"/s/#{stream}", attrs

      location = List.first(get_resp_header(conn, "location"))
      assert flash(conn, :info) =~ ~r/updated/i
      assert response(conn, 302)

      conn = get(build_conn(), location)

      assert html_response(conn, 200) =~ "Haha!"
    end
  end
end
