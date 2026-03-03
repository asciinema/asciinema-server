defmodule AsciinemaWeb.RecordingControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory

  describe "show public recording as owner" do
    setup [:insert_public_recording, :authenticate_as_owner]

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

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
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

    @tag :rsvg
    test "PNG via ID", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :rsvg
    test "GIF via ID", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :rsvg
    test "GIF via secret token", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end
  end

  describe "show unlisted recording as other user" do
    setup [:insert_unlisted_recording, :authenticate_as_other]

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

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v1_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v2_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, asciicast: asciicast} do
      test_cast_v3_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :with_file
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

    @tag :rsvg
    test "PNG via ID", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, asciicast: asciicast} do
      test_png_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end

    @tag :rsvg
    test "GIF via ID", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.id}", 404)
    end

    @tag :rsvg
    test "GIF via secret token", %{conn: conn, asciicast: asciicast} do
      test_gif_response(conn, ~p"/a/#{asciicast.secret_token}", 200)
    end
  end

  describe "show private recording as other user" do
    setup [:insert_private_recording, :authenticate_as_other]

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
    test "JS", %{conn: conn} do
      test_js_response(conn, ~p"/a/99999999", 404)
      test_js_response(conn, ~p"/a/nopenopenope", 404)
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

  describe "deleting" do
    test "requires author", %{conn: conn} do
      user = insert(:user)
      asciicast = insert(:asciicast, user: user)
      conn = log_in(conn, insert(:user))

      conn = delete(conn, ~p"/a/#{asciicast}")

      assert html_response(conn, 403)
    end
  end

  describe "SVG cache-control" do
    setup [:insert_public_recording]

    test "uses 1 year max-age only for matching v param", %{conn: conn, asciicast: asciicast} do
      cache_key = AsciinemaWeb.RecordingSVG.svg_cache_key(asciicast)

      conn = get(conn, ~p"/a/#{asciicast.id}" <> ".svg?v=" <> cache_key)

      assert ["public, max-age=31536000, must-revalidate"] =
               get_resp_header(conn, "cache-control")
    end

    test "uses 1 hour max-age for non-matching v param", %{conn: conn, asciicast: asciicast} do
      conn = get(conn, ~p"/a/#{asciicast.id}" <> ".svg?v=stale")

      assert ["public, max-age=3600, must-revalidate"] = get_resp_header(conn, "cache-control")
    end
  end

  describe "PNG cache-control" do
    setup [:insert_public_recording]

    test "uses 1 hour max-age and etag", %{conn: conn, asciicast: asciicast} do
      conn = get(conn, ~p"/a/#{asciicast.id}" <> ".png")

      assert ["public, max-age=3600, must-revalidate"] = get_resp_header(conn, "cache-control")
      assert [_etag] = get_resp_header(conn, "etag")
    end

    test "returns 304 for matching if-none-match", %{conn: conn, asciicast: asciicast} do
      conn = get(conn, ~p"/a/#{asciicast.id}" <> ".png")
      [etag] = get_resp_header(conn, "etag")

      conn =
        build_conn()
        |> put_req_header("if-none-match", etag)
        |> get(~p"/a/#{asciicast.id}" <> ".png")

      assert response(conn, 304) == ""
    end
  end

  describe "cast gzip encoding" do
    setup [:insert_public_recording]

    @tag :with_file
    test "serves plain .cast/.json when gzip is not requested", %{
      conn: conn,
      asciicast: asciicast
    } do
      conn_1 = get(conn, ~p"/a/#{asciicast.id}" <> ".cast")
      body_1 = asciicast_response(conn_1, 200)

      assert ["accept-encoding"] = get_resp_header(conn_1, "vary")
      assert [] == get_resp_header(conn_1, "content-encoding")
      assert ~s({"version": 2) <> _ = body_1

      conn_2 = get(conn, ~p"/a/#{asciicast.id}" <> ".json")
      body_2 = asciicast_response(conn_2, 200)

      assert ["accept-encoding"] = get_resp_header(conn_2, "vary")
      assert [] == get_resp_header(conn_2, "content-encoding")
      assert ~s({"version": 2) <> _ = body_2
    end

    @tag :with_file
    test "serves gzip .cast/.json when accept-encoding includes gzip", %{
      conn: conn,
      asciicast: asciicast
    } do
      conn_1 =
        conn
        |> put_req_header("accept-encoding", "gzip, deflate")
        |> get(~p"/a/#{asciicast.id}" <> ".cast")

      gzip_body_1 = asciicast_response(conn_1, 200)

      assert ["accept-encoding"] = get_resp_header(conn_1, "vary")
      assert ["gzip"] = get_resp_header(conn_1, "content-encoding")
      assert ~s({"version": 2) <> _ = :zlib.gunzip(gzip_body_1)

      conn_2 =
        conn
        |> put_req_header("accept-encoding", "br, gzip")
        |> get(~p"/a/#{asciicast.id}" <> ".json")

      gzip_body_2 = asciicast_response(conn_2, 200)

      assert ["accept-encoding"] = get_resp_header(conn_2, "vary")
      assert ["gzip"] = get_resp_header(conn_2, "content-encoding")
      assert ~s({"version": 2) <> _ = :zlib.gunzip(gzip_body_2)
    end
  end

  describe "txt gzip encoding" do
    setup [:insert_public_recording]

    @tag :with_file
    test "serves plain .txt when gzip is not requested", %{conn: conn, asciicast: asciicast} do
      conn = get(conn, ~p"/a/#{asciicast.id}" <> ".txt")
      plain_body = response(conn, 200)

      assert ["accept-encoding"] = get_resp_header(conn, "vary")
      assert [] == get_resp_header(conn, "content-encoding")
      assert List.first(get_resp_header(conn, "content-type")) == "text/plain"

      assert List.first(get_resp_header(conn, "content-disposition")) ==
               "attachment; filename=#{asciicast.id}.txt"

      assert is_binary(plain_body)
    end

    @tag :with_file
    test "serves gzip .txt when accept-encoding includes gzip", %{
      conn: conn,
      asciicast: asciicast
    } do
      plain_conn = get(conn, ~p"/a/#{asciicast.id}" <> ".txt")
      plain_body = response(plain_conn, 200)

      gzip_conn =
        conn
        |> put_req_header("accept-encoding", "gzip, br")
        |> get(~p"/a/#{asciicast.id}" <> ".txt")

      gzip_body = response(gzip_conn, 200)

      assert ["accept-encoding"] = get_resp_header(gzip_conn, "vary")
      assert ["gzip"] = get_resp_header(gzip_conn, "content-encoding")
      assert List.first(get_resp_header(gzip_conn, "content-type")) == "text/plain"

      assert List.first(get_resp_header(gzip_conn, "content-disposition")) ==
               "attachment; filename=#{asciicast.id}.txt"

      assert :zlib.gunzip(gzip_body) == plain_body
    end
  end

  describe "svg gzip encoding" do
    setup [:insert_public_recording]

    test "serves plain .svg when gzip is not requested", %{conn: conn, asciicast: asciicast} do
      conn = get(conn, ~p"/a/#{asciicast.id}" <> ".svg")
      plain_body = response(conn, 200)

      assert ["accept-encoding"] = get_resp_header(conn, "vary")
      assert [] == get_resp_header(conn, "content-encoding")
      assert response_content_type(conn, :svg)
      assert plain_body =~ "foo"
      assert plain_body =~ "bar"
    end

    test "serves gzip .svg when accept-encoding includes gzip", %{
      conn: conn,
      asciicast: asciicast
    } do
      plain_conn = get(conn, ~p"/a/#{asciicast.id}" <> ".svg")
      plain_body = response(plain_conn, 200)

      gzip_conn =
        conn
        |> put_req_header("accept-encoding", "deflate, gzip")
        |> get(~p"/a/#{asciicast.id}" <> ".svg")

      gzip_body = response(gzip_conn, 200)

      assert ["accept-encoding"] = get_resp_header(gzip_conn, "vary")
      assert ["gzip"] = get_resp_header(gzip_conn, "content-encoding")
      assert response_content_type(gzip_conn, :svg)
      assert :zlib.gunzip(gzip_body) == plain_body
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

    assert json = asciicast_response(conn_2, 200)
    assert %{"version" => 1} = Jason.decode!(json)

    conn_2 = get(conn, url <> ".json")

    assert json = asciicast_response(conn_2, 200)
    assert %{"version" => 1} = Jason.decode!(json)
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

    body = response(conn_2, 200)
    assert response_content_type(conn_2, :svg)

    # Verify snapshot content is rendered (factory creates snapshot with "foo" and "bar")
    assert body =~ "foo"
    assert body =~ "bar"

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

    conn_2 = get(conn, url <> ".svg?f=t")

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

    conn_2 = get(conn, url <> ".svg?f=t")

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
