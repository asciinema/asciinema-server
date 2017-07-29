defmodule Asciinema.AsciicastImageControllerTest do
  use AsciinemaWeb.ConnCase

  @tag :a2png

  test "renders asciicast image preview", %{conn: conn} do
    asciicast = fixture(:asciicast)
    conn = get conn, asciicast_image_download_path(conn, asciicast)
    assert response(conn, 200)
    assert response_content_type(conn, :png)
  end
end
