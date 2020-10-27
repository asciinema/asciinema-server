defmodule Asciinema.OembedControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory
  alias AsciinemaWeb.Endpoint

  describe "show" do
    test "for JSON format", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = Routes.asciicast_url(Endpoint, :show, asciicast)

      conn =
        get(
          conn,
          Routes.oembed_path(conn, :show,
            url: url,
            format: "json",
            maxwidth: "500",
            maxheight: "300"
          )
        )

      assert response(conn, 200)
      assert response_content_type(conn, :json)
    end

    test "for XML format", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = Routes.asciicast_url(Endpoint, :show, asciicast)

      conn = get(conn, Routes.oembed_path(conn, :show, url: url, format: "xml"))

      assert response(conn, 200)
      assert response_content_type(conn, :xml)
    end

    test "for maxwidth without maxheight", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = Routes.asciicast_url(Endpoint, :show, asciicast)

      conn = get(conn, Routes.oembed_path(conn, :show, url: url, format: "json", maxwidth: "500"))

      assert response(conn, 200)
      assert response_content_type(conn, :json)
    end
  end
end
