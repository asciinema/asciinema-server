defmodule Asciinema.AsciicastFileControllerTest do
  use AsciinemaWeb.ConnCase

  test "renders asciicast file, v1 format", %{conn: conn} do
    asciicast = fixture(:asciicast_v1)
    width = asciicast.terminal_columns
    conn = get conn, asciicast_file_download_path(conn, asciicast)
    assert %{"version" => 1,
             "width" => ^width,
             "stdout" => [_ | _]} = json_response(conn, 200)
  end

  test "renders asciicast file, v2 format", %{conn: conn} do
    asciicast = fixture(:asciicast_v2)
    conn = get conn, asciicast_file_download_path(conn, asciicast)
    assert response(conn, 200)
  end
end
