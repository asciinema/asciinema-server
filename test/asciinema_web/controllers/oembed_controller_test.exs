defmodule AsciinemaWeb.OembedControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory

  describe "show" do
    test "JSON format", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = ~p"/a/#{asciicast}"

      conn =
        get(conn, ~p"/oembed?#{%{url: url, format: "json", maxwidth: "500", maxheight: "300"}}")

      assert json_response(conn, 200)
    end

    test "XML format", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = ~p"/a/#{asciicast}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "xml"}}")

      assert response(conn, 200)
      assert response_content_type(conn, :xml)
    end

    test "maxwidth without maxheight", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = ~p"/a/#{asciicast}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "json", maxwidth: "500"}}")

      assert json_response(conn, 200)
    end

    test "private recording via secret token", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :private)
      url = ~p"/a/#{asciicast.secret_token}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "json"}}")

      assert json_response(conn, 403)
    end

    test "private recording via ID", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :private)
      url = ~p"/a/#{asciicast.id}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "json"}}")

      assert json_response(conn, 404)
    end

    test "unlisted recording via secret token", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :unlisted)
      url = ~p"/a/#{asciicast.secret_token}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "json"}}")

      assert json_response(conn, 200)
    end

    test "unlisted recording via ID", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :unlisted)
      url = ~p"/a/#{asciicast.id}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "json"}}")

      assert json_response(conn, 404)
    end

    test "bad request", %{conn: conn} do
      conn = get(conn, ~p"/oembed?#{%{url: "", format: "json"}}")

      assert json_response(conn, 400)
    end
  end
end
