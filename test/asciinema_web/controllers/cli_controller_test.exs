defmodule AsciinemaWeb.CliControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory

  describe "delete" do
    test "as a guest redirects to login page", %{conn: conn} do
      conn = delete(conn, ~p"/clis/123")

      assert redirected_to(conn, 302) == ~p"/login/new"
      assert flash(conn, :info)
    end

    test "with other user's install_id shows error, redirects to settings", %{conn: conn} do
      user = insert(:user)
      cli = insert(:cli)
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/clis/#{cli.id}")

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :error) =~ ~r/not found/
    end

    test "with unknown install_id shows error, redirects to settings", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/clis/123456789")

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :error) =~ ~r/not found/
    end
  end
end
