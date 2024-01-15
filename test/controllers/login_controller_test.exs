defmodule Asciinema.LoginControllerTest do
  use AsciinemaWeb.ConnCase

  @honeypot_detection_header "x-melliculum"

  test "with valid email", %{conn: conn} do
    conn = post conn, "/login", %{login: %{email: "new@example.com", username: ""}}
    assert redirected_to(conn, 302) == "/login/sent"
    assert get_resp_header(conn, @honeypot_detection_header) == []
  end

  test "with invalid email", %{conn: conn} do
    conn = post conn, "/login", %{login: %{email: "new@", username: ""}}
    assert html_response(conn, 200) =~ "correct email"
    assert get_resp_header(conn, @honeypot_detection_header) == []
  end

  test "as bot with username", %{conn: conn} do
    conn = post conn, "/login", %{login: %{email: "bot@example.com", username: "bot"}}
    assert redirected_to(conn, 302) == "/login/sent"
    assert List.first(get_resp_header(conn, @honeypot_detection_header)) == "machina"
  end

  test "as bot with terms", %{conn: conn} do
    conn = post conn, "/login", %{login: %{email: "bot@example.com", username: "", terms: "1"}}
    assert redirected_to(conn, 302) == "/login/sent"
    assert List.first(get_resp_header(conn, @honeypot_detection_header)) == "machina"
  end
end
