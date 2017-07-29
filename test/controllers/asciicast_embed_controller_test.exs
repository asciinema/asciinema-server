defmodule Asciinema.AsciicastEmbedControllerTest do
  use AsciinemaWeb.ConnCase

  test "serves embed js", %{conn: conn} do
    conn = get conn, "/a/12345.js"
    assert response(conn, 200)
    assert response_content_type(conn, :js)
  end
end
