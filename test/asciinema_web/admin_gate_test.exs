defmodule AsciinemaWeb.AdminGateTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory
  alias Asciinema.AppEnv

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

    test "404s for everyone when disabled", %{conn: conn} do
      AppEnv.put(AsciinemaWeb.Plug.AdminGate, enabled: false)

      user = insert(:user, is_admin: true)

      conn =
        conn
        |> log_in(user)
        |> get("/admin")

      assert response(conn, 404)
    end

    test "404s unknown admin paths", %{conn: conn} do
      user = insert(:user, is_admin: true)

      conn =
        conn
        |> log_in(user)
        |> get("/admin/nope")

      assert response(conn, 404)
    end

    test "dispatches an admin mutation (PUT) for an admin user", %{conn: conn} do
      admin = insert(:user, is_admin: true)
      target = insert(:user, username: "alice")

      conn =
        conn
        |> log_in(admin)
        |> put("/admin/users/#{target.id}", %{
          "user" => %{"username" => "alice", "email" => target.email, "name" => "Renamed"}
        })

      assert redirected_to(conn) == "/admin/users/#{target.id}"
      assert Asciinema.Repo.get!(Asciinema.Accounts.User, target.id).name == "Renamed"
    end

    test "rejects an admin mutation from a non-admin", %{conn: conn} do
      target = insert(:user, name: "Original")

      conn =
        conn
        |> log_in(insert(:user))
        |> put("/admin/users/#{target.id}", %{"user" => %{"name" => "Hacked"}})

      assert response(conn, 404)
      assert Asciinema.Repo.get!(Asciinema.Accounts.User, target.id).name == "Original"
    end

    test "redirects an anonymous admin mutation to login", %{conn: conn} do
      target = insert(:user, name: "Original")

      conn = put(conn, "/admin/users/#{target.id}", %{"user" => %{"name" => "Hacked"}})

      assert redirected_to(conn, 302) == "/login/new"
      assert Asciinema.Repo.get!(Asciinema.Accounts.User, target.id).name == "Original"
    end
  end

  describe "admin panel link in the user dropdown" do
    test "shown to admin user", %{conn: conn} do
      user = insert(:user, is_admin: true)

      html =
        conn
        |> log_in(user)
        |> get(~p"/")
        |> html_response(200)

      assert html =~ "/admin"
      assert html =~ "Admin panel"
    end

    test "hidden from non-admin user", %{conn: conn} do
      user = insert(:user)

      html =
        conn
        |> log_in(user)
        |> get(~p"/")
        |> html_response(200)

      refute html =~ "Admin panel"
    end

    test "hidden when disabled", %{conn: conn} do
      AppEnv.put(AsciinemaWeb.Plug.AdminGate, enabled: false)

      user = insert(:user, is_admin: true)

      html =
        conn
        |> log_in(user)
        |> get(~p"/")
        |> html_response(200)

      refute html =~ "Admin panel"
    end
  end
end
