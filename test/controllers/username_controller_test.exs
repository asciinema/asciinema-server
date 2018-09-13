defmodule Asciinema.UsernameControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  describe "setting username" do
    test "requires logged in user", %{conn: conn} do
      conn = get conn, "/username/new"
      assert redirected_to(conn, 302) == "/login/new"
    end

    test "displays form", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)
      conn = get conn, "/username/new"
      assert html_response(conn, 200) =~ ~r/your username/i
    end

    test "redirects to profile on success", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = post conn, "/username", %{user: %{username: "ricksanchez"}}

      assert response(conn, 302)
      location = List.first(get_resp_header(conn, "location"))
      assert location == "/~ricksanchez"
    end

    test "redisplays form on error", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = post conn, "/username", %{user: %{username: "---"}}

      assert html_response(conn, 422) =~ "only letters"
    end
  end
end
