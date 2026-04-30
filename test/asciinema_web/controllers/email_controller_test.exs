defmodule AsciinemaWeb.EmailControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory
  alias Asciinema.Accounts

  describe "edit" do
    test "renders confirmation without changing email", %{conn: conn} do
      user = insert(:user, email: "old@example.com")
      token = Accounts.generate_email_change_token(user, "new@example.com")

      conn =
        conn
        |> log_in(user)
        |> get(~p"/user/email?t=#{token}")

      assert html_response(conn, 200) =~ "Confirm to finish changing your email address"
      assert Accounts.get_user(user.id).email == "old@example.com"
    end

    test "redirects when token is missing", %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> log_in(user)
        |> get(~p"/user/email")

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :error) =~ "Invalid or expired link"
    end
  end

  describe "update" do
    test "changes email with submitted token", %{conn: conn} do
      user = insert(:user, email: "old@example.com")
      token = Accounts.generate_email_change_token(user, "new@example.com")

      conn =
        conn
        |> log_in(user)
        |> put(~p"/user/email", %{"t" => token})

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :info) =~ "Email address has been changed"
      assert Accounts.get_user(user.id).email == "new@example.com"
    end

    test "rejects token generated for another user", %{conn: conn} do
      user = insert(:user, email: "user@example.com")
      other_user = insert(:user, email: "other@example.com")
      token = Accounts.generate_email_change_token(other_user, "new@example.com")

      conn =
        conn
        |> log_in(user)
        |> put(~p"/user/email", %{"t" => token})

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :error) =~ "generated for another account"
      assert Accounts.get_user(user.id).email == "user@example.com"
      assert Accounts.get_user(other_user.id).email == "other@example.com"
    end
  end
end
