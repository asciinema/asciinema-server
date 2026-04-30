defmodule AsciinemaWeb.UserControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory
  alias Asciinema.Accounts

  describe "new" do
    test "renders confirmation without stashing sign-up token in session", %{conn: conn} do
      token = Accounts.generate_sign_up_token("new@example.com")

      conn = get(conn, ~p"/users/new?t=#{token}")

      assert html_response(conn, 200) =~ "Confirm to create your asciinema account"
      assert get_session(conn, :sign_up_token) == nil
      assert get_session(conn, :user_id) == nil

      conn = post(conn, ~p"/users")

      assert redirected_to(conn, 302) == ~p"/login/new"
      assert flash(conn, :error) =~ "Invalid sign-up link"
      assert get_session(conn, :user_id) == nil
      assert Accounts.find_user("new@example.com") == nil
    end

    test "redirects already logged-in user without accepting sign-up token", %{conn: conn} do
      user = insert(:user, username: "foobar")
      token = Accounts.generate_sign_up_token("attacker@example.com")

      conn =
        conn
        |> log_in(user)
        |> get(~p"/users/new?t=#{token}")

      assert redirected_to(conn, 302) == ~p"/~#{user}"
      assert flash(conn, :info) =~ "already logged in"
      assert get_session(conn, :user_id) == user.id
      assert Accounts.find_user("attacker@example.com") == nil
    end
  end

  describe "create" do
    test "creates and logs user in with submitted token", %{conn: conn} do
      token = Accounts.generate_sign_up_token("new@example.com")

      conn = post(conn, ~p"/users", %{"t" => token, "timezone" => "Etc/UTC"})

      assert redirected_to(conn, 302) == ~p"/username/new"
      assert flash(conn, :info) =~ "Welcome to asciinema"
      assert user = Accounts.get_user(get_session(conn, :user_id))
      assert user.email == "new@example.com"
    end

    test "does not switch accounts when already logged in", %{conn: conn} do
      user = insert(:user, username: "foobar")
      token = Accounts.generate_sign_up_token("attacker@example.com")

      conn =
        conn
        |> log_in(user)
        |> post(~p"/users", %{"t" => token})

      assert redirected_to(conn, 302) == ~p"/~#{user}"
      assert flash(conn, :info) =~ "already logged in"
      assert get_session(conn, :user_id) == user.id
      assert Accounts.find_user("attacker@example.com") == nil
    end
  end
end
