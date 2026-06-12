defmodule AsciinemaAdmin.RedirectControllerTest do
  use AsciinemaAdmin.ConnCase, async: true

  test "GET / redirects to /admin", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert redirected_to(conn) == ~p"/admin"
  end
end
