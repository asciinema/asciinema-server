defmodule AsciinemaWeb.AdminGateTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  describe "admin panel via the main endpoint" do
    test "redirects anonymous user to login", %{conn: conn} do
      conn = get(conn, "/admin")

      assert redirected_to(conn, 302) == "/login/new"
      assert get_session(conn, :return_to) == "/admin"
    end

    test "returns 404 to non-admin user", %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> log_in(user)
        |> get("/admin")

      assert response(conn, 404)
    end

    test "renders dashboard to admin user", %{conn: conn} do
      user = insert(:user, is_admin: true)

      conn =
        conn
        |> log_in(user)
        |> get("/admin")

      assert html_response(conn, 200) =~ "Dashboard"
    end

    test "dispatches nested admin paths", %{conn: conn} do
      user = insert(:user, is_admin: true)

      conn =
        conn
        |> log_in(user)
        |> get("/admin/users")

      assert html_response(conn, 200)
    end

    test "dispatches live dashboard", %{conn: conn} do
      user = insert(:user, is_admin: true)

      conn =
        conn
        |> log_in(user)
        |> get("/admin/system/dashboard")

      assert redirected_to(conn, 302) =~ "/admin/system/dashboard/"
    end

    test "404s unknown admin paths", %{conn: conn} do
      user = insert(:user, is_admin: true)

      conn =
        conn
        |> log_in(user)
        |> get("/admin/nope")

      assert response(conn, 404)
    end
  end
end
