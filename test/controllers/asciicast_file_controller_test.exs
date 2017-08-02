defmodule Asciinema.AsciicastFileControllerTest do
  use AsciinemaWeb.ConnCase

  test "renders asciicast file", %{conn: conn} do
    asciicast = fixture(:asciicast)
    width = asciicast.terminal_columns
    conn = get conn, asciicast_file_download_path(conn, asciicast)
    assert %{"version" => 1,
             "width" => ^width,
             "stdout" => [_ | _]} = json_response(conn, 200)
  end
end
