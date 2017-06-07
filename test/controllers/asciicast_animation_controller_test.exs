defmodule Asciinema.AsciicastAnimationControllerTest do
  use Asciinema.ConnCase

  test "shows GIF generation instructions", %{conn: conn} do
    asciicast = fixture(:asciicast)
    conn = get conn, asciicast_animation_download_path(conn, asciicast)
    assert html_response(conn, 200) =~ "GIF"
  end
end
