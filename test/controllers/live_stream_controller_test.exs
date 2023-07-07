defmodule Asciinema.LiveStreamControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  describe "show" do
    test "HTML, private stream via ID", %{conn: conn} do
      stream = insert(:live_stream, private: true)

      conn_2 = get(conn, "/s/#{stream.id}")

      assert html_response(conn_2, 404)
    end

    test "HTML, private stream via secret token", %{conn: conn} do
      asciicast = insert(:live_stream, private: true)

      conn_2 = get(conn, "/s/#{asciicast.secret_token}")

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
  end
end
