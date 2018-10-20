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
      assert get_flash(conn, :info) =~ ~r/welcome/i
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

  describe "profile page" do
    test "via ID based path", %{conn: conn} do
      user = insert(:user, username: "dracula3000")
      conn = log_in(conn, user)
      conn = get conn, "/u/#{user.id}"
      assert html_response(conn, 200) =~ "dracula3000"
    end

    test "via username based path", %{conn: conn} do
      user = insert(:user, username: "dracula3000")
      conn = log_in(conn, user)
      conn = get conn, "/~dracula3000"
      assert html_response(conn, 200) =~ "dracula3000"
    end

    test "asciicast visibility" do
      user = insert(:user, username: "dracula3000")
      insert(:asciicast, user: user, private: false, title: "Public stuff")
      insert(:asciicast, user: user, private: true, title: "Private stuff")

      # as guest

      conn = get build_conn(), "/~dracula3000"

      html = html_response(conn, 200)
      assert html =~ "1 public"
      assert html =~ "Public stuff"
      refute html =~ "Private stuff"

      # as himself

      conn = log_in build_conn(), user

      conn = get conn, "/~dracula3000"
      html = html_response(conn, 200)
      assert html =~ "2 asciicasts"
      assert html =~ "Public stuff"
      assert html =~ "Private stuff"
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
      assert get_flash(conn, :info) =~ ~r/saved/i
      assert response(conn, 302)
      assert location == "/~#{user.username}"
    end
  end
end
