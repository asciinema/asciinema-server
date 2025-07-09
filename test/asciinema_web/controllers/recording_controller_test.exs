defmodule AsciinemaWeb.RecordingControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory

  describe "explore" do
    setup do
      insert(:asciicast, visibility: :public, featured: true, title: "Featured stuff")
      insert(:asciicast, visibility: :public, title: "Good stuff")

      :ok
    end

    test "auto", %{conn: conn} do
      conn = get(conn, ~p"/explore")

      html = html_response(conn, 200)
      assert html =~ "Featured stuff"
      refute html =~ "Good stuff"
    end

    test "public", %{conn: conn} do
      conn = get(conn, ~p"/explore/public")

      html = html_response(conn, 200)
      assert html =~ "Good stuff"
      assert html =~ "Featured stuff"
    end

    test "featured", %{conn: conn} do
      conn = get(conn, ~p"/explore/featured")

      html = html_response(conn, 200)
      assert html =~ "Featured stuff"
      refute html =~ "Good stuff"
    end
  end

  describe "show public recording as owner" do
    setup [:insert_public_recording, :authenticate_as_owner]

    test "HTML via ID", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "HTML via secret token", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.secret_token}", {302, ~p"/a/#{asciicast.id}"})
    end

    test "JS via ID", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "JS via secret token", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.id}/iframe", 200)
    end

    test "IFRAME via secret token", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.secret_token}/iframe", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    test "TXT via ID", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "SVG via secret token", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :rsvg
    test "PNG via ID", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "GIF via ID", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "GIF via secret token", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end
  end

  describe "show public recording as other user" do
    setup [:insert_public_recording, :authenticate_as_other]

    test "HTML via ID", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "HTML via secret token", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.secret_token}", {302, ~p"/a/#{asciicast.id}"})
    end

    test "JS via ID", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "JS via secret token", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.id}/iframe", 200)
    end

    test "IFRAME via secret token", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.secret_token}/iframe", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    test "TXT via ID", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "SVG via secret token", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :rsvg
    test "PNG via ID", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "GIF via ID", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "GIF via secret token", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end
  end

  describe "show public recording as guest" do
    setup [:insert_public_recording]

    test "HTML via ID", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "HTML via secret token", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.secret_token}", {302, ~p"/a/#{asciicast.id}"})
    end

    test "JS via ID", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "JS via secret token", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.id}/iframe", 200)
    end

    test "IFRAME via secret token", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.secret_token}/iframe", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    test "TXT via ID", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "SVG via secret token", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :rsvg
    test "PNG via ID", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "GIF via ID", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "GIF via secret token", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end
  end

  describe "show unlisted recording as owner" do
    setup [:insert_unlisted_recording, :authenticate_as_owner]

    test "HTML via ID", %{conn: conn, asciicast: asciicast} do
      test_html_response(
        conn,
        ~p"/a/#{asciicast.id}",
        {302, ~p"/a/#{asciicast.secret_token}"}
      )
    end

    test "HTML via secret token", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "JS via ID", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "JS via secret token", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.id}/iframe", 200)
    end

    test "IFRAME via secret token", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.secret_token}/iframe", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    test "TXT via ID", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "SVG via secret token", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :rsvg
    test "PNG via ID", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :rsvg
    test "GIF via ID", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :rsvg
    test "GIF via secret token", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end
  end

  describe "show unlisted recording as other user" do
    setup [:insert_unlisted_recording, :authenticate_as_other]

    test "HTML via ID", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "HTML via secret token", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "JS via ID", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "JS via secret token", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.id}/iframe", 404)
    end

    test "IFRAME via secret token", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.secret_token}/iframe", 200)
    end

    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "TXT via ID", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "SVG via secret token", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "PNG via ID", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "GIF via ID", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "GIF via secret token", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end
  end

  describe "show unlisted recording as guest" do
    setup [:insert_unlisted_recording]

    test "HTML via ID", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "HTML via secret token", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "JS via ID", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "JS via secret token", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.id}/iframe", 404)
    end

    test "IFRAME via secret token", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.secret_token}/iframe", 200)
    end

    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "TXT via ID", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "SVG via secret token", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "PNG via ID", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "GIF via ID", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "GIF via secret token", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end
  end

  describe "show private recording as owner" do
    setup [:insert_private_recording, :authenticate_as_owner]

    test "HTML via ID", %{conn: conn, asciicast: asciicast} do
      test_html_response(
        conn,
        ~p"/a/#{asciicast.id}",
        {302, ~p"/a/#{asciicast.secret_token}"}
      )
    end

    test "HTML via secret token", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "JS via ID", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "JS via secret token", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.id}/iframe", 200)
    end

    test "IFRAME via secret token", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.secret_token}/iframe", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    test "TXT via ID", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    test "SVG via secret token", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :rsvg
    test "PNG via ID", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :rsvg
    test "GIF via ID", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.id}", 200)
    end

    @tag :rsvg
    test "GIF via secret token", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end
  end

  describe "show private recording as other user" do
    setup [:insert_private_recording, :authenticate_as_other]

    test "HTML via ID", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "HTML via secret token", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "JS via ID", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "JS via secret token", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "IFRAME via ID", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.id}/iframe", 404)
    end

    test "IFRAME via secret token", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.secret_token}/iframe", 403)
    end

    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "TXT via ID", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "TXT via secret token", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "SVG via ID", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "SVG via secret token", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "PNG via ID", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "PNG via secret token", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "GIF via ID", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "GIF via secret token", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end
  end

  describe "show private recording as guest" do
    setup [:insert_private_recording]

    test "HTML via ID", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "HTML via secret token", %{conn: conn, asciicast: asciicast} do
      test_html_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "JS via ID", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "JS via secret token", %{conn: conn, asciicast: asciicast} do
      test_js_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "IFRAME via ID", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.id}/iframe", 404)
    end

    test "IFRAME via secret token", %{conn: conn, asciicast: asciicast} do
      test_iframe_response(conn, ~p"/a/#{asciicast.secret_token}/iframe", 403)
    end

    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "TXT via ID", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "TXT via secret token", %{conn: conn, asciicast: asciicast} do
      test_txt_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "SVG via ID", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "SVG via secret token", %{conn: conn, asciicast: asciicast} do
      test_svg_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "PNG via ID", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "PNG via secret token", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end

    test "GIF via ID", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    test "GIF via secret token", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.secret_token}", 403)
    end
  end

  describe "show non-existing recording" do
    test "HTML", %{conn: conn} do
      conn = get(conn, ~p"/a/99999999")

      assert html_response(conn, 404)
    end

    test "TXT", %{conn: conn} do
      url = ~p"/a/99999999"

      conn_2 = get(conn, url <> ".txt")

      assert text_response(conn_2, 404)

      conn_2 =
        conn
        |> put_req_header("accept", "text/plain")
        |> get(url)

      assert text_response(conn_2, 404)
    end
  end

  describe "editing" do
    setup ctx do
      user = insert(:user)

      Map.merge(ctx, %{
        user: user,
        asciicast: insert(:asciicast, user: user)
      })
    end

    test "requires logged in user", %{conn: conn, asciicast: asciicast} do
      conn = get(conn, ~p"/a/#{asciicast}/edit")

      assert redirected_to(conn, 302) == ~p"/login/new"
    end

    test "requires author", %{conn: conn, asciicast: asciicast} do
      conn = log_in(conn, insert(:user))

      conn = get(conn, ~p"/a/#{asciicast}/edit")

      assert html_response(conn, 403)
    end

    test "displays form", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)

      conn = get(conn, ~p"/a/#{asciicast}/edit")

      assert html_response(conn, 200) =~ "Save"
    end

    test "updates title", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)
      attrs = %{asciicast: %{title: "Haha!"}}

      conn = put conn, ~p"/a/#{asciicast}", attrs

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
        asciicast: insert(:asciicast, user: user) |> with_file()
      })
    end

    test "requires author", %{conn: conn, asciicast: asciicast} do
      conn = log_in(conn, insert(:user))

      conn = delete(conn, ~p"/a/#{asciicast}")

      assert html_response(conn, 403)
    end

    test "removes and redirects", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/a/#{asciicast}")

      assert flash(conn, :info) =~ ~r/deleted/i
      assert response(conn, 302)

      conn = get(build_conn(), ~p"/a/#{asciicast}")

      assert html_response(conn, 404) =~ ~r/not found/i
    end
  end

  defp insert_public_recording(context) do
    [asciicast: insert_recording(:public, context)]
  end

  defp insert_unlisted_recording(context) do
    [asciicast: insert_recording(:unlisted, context)]
  end

  defp insert_private_recording(context) do
    [asciicast: insert_recording(:private, context)]
  end

  defp insert_recording(visibility, context) do
    version = Map.get(context, :version, 2)
    with_file = Map.get(context, :with_file, false)

    asciicast = insert(:"asciicast_v#{version}", visibility: visibility)

    if with_file do
      with_file(asciicast)
    else
      asciicast
    end
  end

  defp authenticate_as_owner(%{conn: conn, asciicast: asciicast}) do
    [conn: log_in(conn, asciicast.user)]
  end

  defp authenticate_as_other(%{conn: conn}) do
    [conn: log_in(conn, insert(:user))]
  end

  defp test_html_response(conn, url, 200) do
    conn_2 =
      conn
      |> put_req_header("accept", "*/*")
      |> get(url)

    html = html_response(conn_2, 200)
    assert html =~ "createPlayer"
    assert html =~ "application/json+oembed"
    assert html =~ "application/x-asciicast"

    conn_2 =
      conn
      |> put_req_header("accept", "text/html")
      |> get(url)

    assert html_response(conn_2, 200) =~ "createPlayer"
  end

  defp test_html_response(conn, url, {302, location}) do
    conn = get(conn, url)

    assert redirected_to(conn, 302) == location
  end

  defp test_html_response(conn, url, status) when status >= 400 do
    conn = get(conn, url)

    assert html_response(conn, status)
  end

  defp test_js_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".js")

    assert response(conn_2, 200)
    assert response_content_type(conn_2, :js)

    conn_2 =
      conn
      |> put_req_header("accept", "application/javascript")
      |> get(url)

    assert response(conn_2, 200)
    assert response_content_type(conn_2, :js)
  end

  defp test_js_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".js")

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "application/javascript")
      |> get(url)

    assert text_response(conn_2, status)
  end

  defp test_iframe_response(conn, url, 200) do
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

  defp test_iframe_response(conn, url, status) when status >= 400 do
    conn = get(conn, url)

    assert html_response(conn, status)
  end

  defp test_cast_v1_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".cast")

    assert %{"version" => 1} = json_response(conn_2, 200)

    conn_2 = get(conn, url <> ".json")

    assert %{"version" => 1} = json_response(conn_2, 200)
  end

  defp test_cast_v1_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".cast")

    assert text_response(conn_2, status)

    conn_2 = get(conn, url <> ".json")

    assert json_response(conn_2, status)
  end

  defp test_cast_v2_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".cast")

    assert ~s({"version": 2) <> _ = asciicast_response(conn_2, 200)
  end

  defp test_cast_v2_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".cast")

    assert text_response(conn_2, status)
  end

  defp test_cast_v3_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".cast")

    assert ~s({"version": 3) <> _ = asciicast_response(conn_2, 200)
  end

  defp test_cast_v3_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".cast")

    assert text_response(conn_2, status)
  end

  defp test_txt_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".txt")

    assert text_response(conn_2, 200)

    conn_2 =
      conn
      |> put_req_header("accept", "text/plain")
      |> get(url)

    assert text_response(conn_2, 200)
  end

  defp test_txt_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".txt")

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "text/plain")
      |> get(url)

    assert text_response(conn_2, status)
  end

  defp test_svg_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".svg")

    assert response(conn_2, 200)
    assert response_content_type(conn_2, :svg)

    conn_2 =
      conn
      |> put_req_header("accept", "image/svg+xml")
      |> get(url)

    assert response(conn_2, 200)
    assert response_content_type(conn_2, :svg)

    conn_2 =
      conn
      |> put_req_header("accept", "image/*")
      |> get(url)

    assert response(conn_2, 200)
    assert response_content_type(conn_2, :svg)
  end

  defp test_svg_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".svg")

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "image/svg+xml")
      |> get(url)

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "image/*")
      |> get(url)

    assert text_response(conn_2, status)
  end

  defp test_png_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".png")

    assert png_response(conn_2, 200)

    conn_2 =
      conn
      |> put_req_header("accept", "image/png")
      |> get(url)

    assert png_response(conn_2, 200)
  end

  defp test_png_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".png")

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "image/png")
      |> get(url)

    assert text_response(conn_2, status)
  end

  defp test_gif_response(conn, url, 200) do
    conn = get(conn, url <> ".gif")

    assert html_response(conn, 200) =~ "GIF"
  end

  defp test_gif_response(conn, url, status) when status >= 400 do
    conn = get(conn, url <> ".gif")

    assert text_response(conn, status)
  end

  defp asciicast_response(conn, 200) do
    body = response(conn, 200)
    assert List.first(get_resp_header(conn, "content-type")) == "application/x-asciicast"

    body
  end

  defp png_response(conn, status) do
    _ = response(conn, status)
    assert response_content_type(conn, :png)

    true
  end
end
