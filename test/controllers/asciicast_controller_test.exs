defmodule Asciinema.AsciicastControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  test "lists asciicasts", %{conn: conn} do
    insert(:asciicast, private: false, title: "Good stuff")
    insert(:asciicast, featured: true, title: "Featured stuff")

    conn = get conn, asciicast_path(conn, :index)
    assert html_response(conn, 200) =~ "Good stuff"

    conn = get conn, asciicast_path(conn, :index, order: "popularity")
    assert html_response(conn, 200) =~ "Good stuff"

    conn = get conn, asciicast_path(conn, :index, order: "date", page: "2")
    refute html_response(conn, 200) =~ "Good stuff"

    conn = get conn, asciicast_path(conn, :featured)
    assert html_response(conn, 200) =~ "Featured stuff"
  end

  test "shows asciicast file, v1 format", %{conn: conn} do
    asciicast = fixture(:asciicast_v1)
    width = asciicast.terminal_columns
    conn = get conn, asciicast_file_path(conn, asciicast)
    assert %{"version" => 1,
             "width" => ^width,
             "stdout" => [_ | _]} = json_response(conn, 200)
  end

  test "shows asciicast file, v2 format", %{conn: conn} do
    asciicast = fixture(:asciicast_v2)
    conn = get conn, asciicast_file_path(conn, asciicast)
    assert response(conn, 200)
  end

  @tag :a2png
  test "shows png preview", %{conn: conn} do
    asciicast = fixture(:asciicast)
    conn = get conn, asciicast_image_path(conn, asciicast)
    assert response(conn, 200)
    assert response_content_type(conn, :png)
  end

  test "shows GIF generation instructions", %{conn: conn} do
    asciicast = fixture(:asciicast)
    conn = get conn, asciicast_animation_path(conn, asciicast)
    assert html_response(conn, 200) =~ "GIF"
    assert response_content_type(conn, :html)
  end

  test "shows embed js", %{conn: conn} do
    asciicast = fixture(:asciicast)
    conn = get conn, asciicast_path(conn, :show, asciicast) <> ".js"
    assert response(conn, 200)
    assert response_content_type(conn, :js)
  end
end
