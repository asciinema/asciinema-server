defmodule Asciinema.OembedControllerTest do
  use AsciinemaWeb.ConnCase
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

    test "private recording", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :private)
      url = ~p"/a/#{asciicast}"

      conn =
        get(conn, ~p"/oembed?#{%{url: url, format: "json", maxwidth: "500", maxheight: "300"}}")

      assert json_response(conn, 403)
    end
  end
end
