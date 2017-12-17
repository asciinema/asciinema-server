defmodule Asciinema.UserControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory
  alias Asciinema.Accounts

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  test "successful sign-up", %{conn: conn} do
    conn = get conn, "/users/new", t: Accounts.signup_token("test@example.com")
    assert redirected_to(conn, 302) == "/users/new"

    conn = get conn, "/users/new"
    assert html_response(conn, 200)

    conn = post conn, "/users"
    assert redirected_to(conn, 302) == "/username/new"
    assert get_rails_flash(conn, :notice) =~ ~r/welcome/i
  end

  test "failed sign-up due to email taken", %{conn: conn} do
    insert(:user, email: "test@example.com")

    conn = get conn, "/users/new", t: Accounts.signup_token("test@example.com")
    assert redirected_to(conn, 302) == "/users/new"

    conn = get conn, "/users/new"
    assert html_response(conn, 200)

    conn = post conn, "/users"
    assert redirected_to(conn, 302) == "/login/new"
    assert get_flash(conn, :error) =~ ~r/already/i
  end

  test "failed sign-up due to invalid token", %{conn: conn} do
    conn = get conn, "/users/new", t: "nope"
    assert redirected_to(conn, 302) == "/users/new"

    conn = get conn, "/users/new"
    assert html_response(conn, 200)

    conn = post conn, "/users"
    assert redirected_to(conn, 302) == "/login/new"
    assert get_flash(conn, :error) =~ ~r/invalid/i
  end
end
