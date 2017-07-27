defmodule Asciinema.LoginControllerTest do
  use Asciinema.ConnCase

  test "with valid email", %{conn: conn} do
    conn = post conn, "/login", %{login: %{email: "new@example.com"}}
    assert redirected_to(conn, 302) == "/login/sent"
  end

  test "with invalid email", %{conn: conn} do
    conn = post conn, "/login", %{login: %{email: "new@"}}
    assert html_response(conn, 200) =~ "correct email"
  end
end
