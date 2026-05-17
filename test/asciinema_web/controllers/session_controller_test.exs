defmodule AsciinemaWeb.SessionControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory
  alias Asciinema.Accounts

  describe "new" do
    test "renders confirmation without stashing login token in session", %{conn: conn} do
      user = insert(:user)
      token = Accounts.generate_login_token(user)

      conn = get(conn, ~p"/session/new?t=#{token}")

      assert html_response(conn, 200) =~ "Confirm to finish logging in"
      assert get_session(conn, :login_token) == nil
      assert get_session(conn, :user_id) == nil

      conn = post(conn, ~p"/session")

      assert redirected_to(conn, 302) == ~p"/login/new"
      assert flash(conn, :error) =~ "Invalid login link"
      assert get_session(conn, :user_id) == nil
    end

    test "redirects already logged-in user without accepting login token", %{conn: conn} do
      victim = insert(:user, username: "victim")
      attacker = insert(:user, username: "attacker")
      token = Accounts.generate_login_token(attacker)

      conn =
        conn
        |> log_in(victim)
        |> get(~p"/session/new?t=#{token}")

      assert redirected_to(conn, 302) == ~p"/~#{victim}"
      assert flash(conn, :info) =~ "already logged in"
      assert get_session(conn, :user_id) == victim.id
    end
  end

  describe "create" do
    test "logs user in with submitted token", %{conn: conn} do
      user = insert(:user, username: "foobar", timezone: nil)
      token = Accounts.generate_login_token(user)

      conn = post(conn, ~p"/session", %{"t" => token, "timezone" => "Etc/UTC"})

      assert redirected_to(conn, 302) == ~p"/~#{user}"
      assert flash(conn, :info) =~ "Welcome back"
      assert get_session(conn, :user_id) == user.id
    end

    test "does not switch accounts when already logged in", %{conn: conn} do
      victim = insert(:user, username: "victim")
      attacker = insert(:user, username: "attacker")
      token = Accounts.generate_login_token(attacker)

      conn =
        conn
        |> log_in(victim)
        |> post(~p"/session", %{"t" => token})

      assert redirected_to(conn, 302) == ~p"/~#{victim}"
      assert flash(conn, :info) =~ "already logged in"
      assert get_session(conn, :user_id) == victim.id
    end
  end
end
