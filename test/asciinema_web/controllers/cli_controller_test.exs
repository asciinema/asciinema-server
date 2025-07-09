defmodule AsciinemaWeb.CliControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory

  describe "register" do
    test "as a guest redirects to login page", %{conn: conn} do
      conn = get(conn, ~p"/connect/00000000-0000-0000-0000-000000000000")

      assert redirected_to(conn, 302) == ~p"/login/new"
      assert flash(conn, :info)
    end

    test "with invalid install_id shows error", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/nopenope")

      assert redirected_to(conn, 302) == "/"
      assert flash(conn, :error) =~ ~r/invalid/i
    end

    test "with revoked install_id shows error", %{conn: conn} do
      user = insert(:user)
      cli = insert(:revoked_cli, user: user)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{cli.token}")

      assert redirected_to(conn, 302) == "/"
      assert flash(conn, :error) =~ ~r/been revoked/i
    end

    test "with tmp user install_id shows notice, redirects to profile page", %{conn: conn} do
      user = insert(:user, username: "test")
      tmp_user = insert(:temporary_user)
      cli = insert(:cli, user: tmp_user)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{cli.token}")

      assert redirected_to(conn, 302) == ~p"/~test"
      assert flash(conn, :info) =~ ~r/successfully/
    end

    test "with their own install_id shows notice, redirects to profile page", %{conn: conn} do
      user = insert(:user, username: "test")
      cli = insert(:cli, user: user)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{cli.token}")

      assert redirected_to(conn, 302) == ~p"/~test"
      assert flash(conn, :info) =~ ~r/successfully/
    end

    test "with other user's install_id shows error, redirects to profile page", %{conn: conn} do
      user = insert(:user, username: "test")
      cli = insert(:cli)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{cli.token}")

      assert redirected_to(conn, 302) == ~p"/~test"
      assert flash(conn, :error) =~ ~r/different/
    end
  end

  describe "delete" do
    test "as a guest redirects to login page", %{conn: conn} do
      conn = delete(conn, ~p"/clis/123")

      assert redirected_to(conn, 302) == ~p"/login/new"
      assert flash(conn, :info)
    end

    test "with user's own install_id shows notice, redirects to settings", %{conn: conn} do
      user = insert(:user)
      cli = insert(:cli, user: user)
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/clis/#{cli.id}")

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :info) =~ ~r/revoked/
    end

    test "with other user's install_id shows error, redirects to settings", %{conn: conn} do
      user = insert(:user)
      cli = insert(:cli)
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/clis/#{cli.id}")

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :error) =~ ~r/not found/
    end

    test "with invalid install_id shows error, redirects to settings", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/clis/123456789")

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :error) =~ ~r/not found/
    end
  end
end
