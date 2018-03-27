defmodule Asciinema.PageControllerTest do
  use AsciinemaWeb.ConnCase

  test "static pages", %{conn: conn} do
    Enum.each(["/about",
               "/privacy",
               "/contributing",
               "/contact",
               "/tos"], fn(path) ->
      conn = get conn, path
      assert html_response(conn, 200) =~ ~r{<h1>.+</h1>}
    end)
  end
end
