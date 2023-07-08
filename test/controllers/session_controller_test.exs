defmodule Asciinema.SessionControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory
  alias Asciinema.Repo
  alias Asciinema.Accounts

  test "successful log-in", %{conn: conn} do
    user = insert(:user, email: "test@example.com", username: "blazko")

    conn = get conn, "/session/new", t: Accounts.login_token(user)
    assert redirected_to(conn, 302) == "/session/new"

    conn = get(conn, "/session/new")
    assert html_response(conn, 200)

    conn = post(conn, "/session")
    assert redirected_to(conn, 302) == "/~blazko"
    assert flash(conn, :info) =~ ~r/welcome/i
  end

  test "failed log-in due to invalid token", %{conn: conn} do
    conn = get conn, "/session/new", t: "nope"
    assert redirected_to(conn, 302) == "/session/new"

    conn = get(conn, "/session/new")
    assert html_response(conn, 200)

    conn = post(conn, "/session")
    assert redirected_to(conn, 302) == "/login/new"
    assert flash(conn, :error) =~ ~r/invalid/i
  end

  test "failed log-in due to account removed", %{conn: conn} do
    user = insert(:user, email: "test@example.com", username: "blazko")
    token = Accounts.login_token(user)
    Repo.delete!(user)

    conn = get conn, "/session/new", t: token
    assert redirected_to(conn, 302) == "/session/new"

    conn = get(conn, "/session/new")
    assert html_response(conn, 200)

    conn = post(conn, "/session")
    assert redirected_to(conn, 302) == "/login/new"
    assert flash(conn, :error) =~ ~r/removed/i
  end

  test "logout", %{conn: conn} do
    user = insert(:user)
    conn = log_in(conn, user)

    conn = delete(conn, "/session")

    assert redirected_to(conn, 302) == "/"
    assert flash(conn, :info) =~ ~r/see you/i
  end
end
