defmodule Asciinema.DocControllerTest do
  use Asciinema.ConnCase

  test "GET /docs", %{conn: conn} do
    conn = get conn, "/docs"
    assert redirected_to(conn, 302) == "/docs/getting-started"
  end

  test "GET /docs/*", %{conn: conn} do
    Enum.each(["/docs/how-it-works",
               "/docs/getting-started",
               "/docs/installation",
               "/docs/usage",
               "/docs/config",
               "/docs/embedding",
               "/docs/faq"], fn(path) ->
      conn = get conn, path
      assert html_response(conn, 200) =~ "<h2>Docs</h2>"
    end)
  end

end
