defmodule Asciinema.LiveStreamControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  describe "show" do
    test "public stream", %{conn: conn} do
      stream = insert(:live_stream, visibility: :public)

      conn_2 = get(conn, ~p"/s/#{stream}")

      assert html_response(conn_2, 200) =~ "createPlayer"
    end

    test "unlisted stream", %{conn: conn} do
      stream = insert(:live_stream, visibility: :unlisted)

      conn_2 = get(conn, ~p"/s/#{stream}")

      assert html_response(conn_2, 200) =~ "createPlayer"
    end

    test "private stream, unauthenticated", %{conn: conn} do
      stream = insert(:live_stream, visibility: :private)

      conn_2 = get(conn, ~p"/s/#{stream}")

      assert redirected_to(conn_2, 302) == ~p"/login/new"
    end

    test "private stream, as non-owner", %{conn: conn} do
      stream = insert(:live_stream, visibility: :private)
      user = insert(:user)
      conn = log_in(conn, user)

      conn_2 = get(conn, ~p"/s/#{stream}")

      assert html_response(conn_2, 403)
    end

    test "private stream, as owner", %{conn: conn} do
      user = insert(:user)
      stream = insert(:live_stream, visibility: :private, user: user)
      conn = log_in(conn, user)

      conn_2 = get(conn, ~p"/s/#{stream}")

      assert html_response(conn_2, 200) =~ "createPlayer"
    end

    test "streaming instructions", %{conn: conn} do
      user = insert(:user)
      stream = insert(:live_stream, user: user)

      conn_2 = get(conn, ~p"/s/#{stream}")
      refute html_response(conn_2, 200) =~ stream.producer_token

      conn_2 = log_in(conn, insert(:user))
      conn_2 = get(conn_2, ~p"/s/#{stream}")
      refute html_response(conn_2, 200) =~ stream.producer_token

      conn_2 = log_in(conn, user)
      conn_2 = get(conn_2, ~p"/s/#{stream}")
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
