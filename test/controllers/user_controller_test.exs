defmodule Asciinema.UserControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory
  alias Asciinema.Accounts

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  describe "sign-up" do
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

  describe "account editing" do
    test "requires logged in user", %{conn: conn} do
      conn = get conn, "/user/edit"
      assert redirected_to(conn, 302) == "/login/new"
    end

    test "displays form", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)
      conn = get conn, "/user/edit"
      assert html_response(conn, 200) =~ "Save"
    end

    test "update name", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)
      conn = put conn, "/user", %{user: %{name: "Rick"}}
      location = List.first(get_resp_header(conn, "location"))
      assert get_rails_flash(conn, :notice) =~ ~r/saved/i
      assert response(conn, 302)
      assert location == "/~#{user.username}"
    end
  end
end
