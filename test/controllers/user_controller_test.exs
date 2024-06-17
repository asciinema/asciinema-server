defmodule Asciinema.UserControllerTest do
  use AsciinemaWeb.ConnCase
  use Oban.Testing, repo: Asciinema.Repo
  import Asciinema.Factory
  import Swoosh.TestAssertions
  alias Asciinema.Accounts

  describe "sign-up" do
    test "success", %{conn: conn} do
      conn = get conn, ~p"/users/new", t: Accounts.sign_up_token("test@example.com")
      assert redirected_to(conn, 302) == ~p"/users/new"

      conn = get(conn, ~p"/users/new")
      assert html_response(conn, 200)

      conn = post(conn, ~p"/users")
      assert redirected_to(conn, 302) == ~p"/username/new"
      assert flash(conn, :info) =~ ~r/welcome/i
    end

    test "failure - email taken", %{conn: conn} do
      insert(:user, email: "test@example.com")

      conn = get conn, ~p"/users/new", t: Accounts.sign_up_token("test@example.com")
      assert redirected_to(conn, 302) == ~p"/users/new"

      conn = get(conn, ~p"/users/new")
      assert html_response(conn, 200)

      conn = post(conn, ~p"/users")
      assert redirected_to(conn, 302) == ~p"/login/new"
      assert flash(conn, :error) =~ ~r/already/i
    end

    test "failure - invalid token", %{conn: conn} do
      conn = get conn, ~p"/users/new", t: "nope"
      assert redirected_to(conn, 302) == ~p"/users/new"

      conn = get(conn, ~p"/users/new")
      assert html_response(conn, 200)

      conn = post(conn, ~p"/users")
      assert redirected_to(conn, 302) == ~p"/login/new"
      assert flash(conn, :error) =~ ~r/invalid/i
    end
  end

  describe "show" do
    test "by ID", %{conn: conn} do
      user = insert(:user, username: "dracula3000")
      conn = log_in(conn, user)

      conn = get(conn, ~p"/u/#{user}")

      assert html_response(conn, 200) =~ "dracula3000"
    end

    test "by username", %{conn: conn} do
      user = insert(:user, username: "dracula3000")
      conn = log_in(conn, user)

      conn = get(conn, ~p"/~dracula3000")

      assert html_response(conn, 200) =~ "dracula3000"
    end

    test "asciicast visibility, as guest", %{conn: conn} do
      user = insert(:user, username: "dracula3000")
      insert(:asciicast, user: user, visibility: :public, title: "Public stuff")
      insert(:asciicast, user: user, visibility: :unlisted, title: "Unlisted stuff")
      insert(:asciicast, user: user, visibility: :private, title: "Private stuff")

      conn = get(conn, ~p"/~dracula3000")

      html = html_response(conn, 200)
      assert html =~ "1 public"
      assert html =~ "Public stuff"
      refute html =~ "Unlisted stuff"
      refute html =~ "Private stuff"
    end

    test "asciicast visibility, as owner", %{conn: conn} do
      user = insert(:user, username: "dracula3000")
      insert(:asciicast, user: user, visibility: :public, title: "Public stuff")
      insert(:asciicast, user: user, visibility: :unlisted, title: "Unlisted stuff")
      insert(:asciicast, user: user, visibility: :private, title: "Private stuff")
      conn = log_in(conn, user)

      conn = get(conn, ~p"/~dracula3000")

      html = html_response(conn, 200)
      assert html =~ "3 recordings"
      assert html =~ "Public stuff"
      assert html =~ "Unlisted stuff"
      assert html =~ "Private stuff"
    end
  end

  describe "edit" do
    test "requires logged in user", %{conn: conn} do
      conn = get(conn, ~p"/user/edit")

      assert redirected_to(conn, 302) == ~p"/login/new"
    end

    test "displays form", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/user/edit")

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "update" do
    test "updates name", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = put conn, ~p"/user", %{user: %{name: "Rick"}}

      location = List.first(get_resp_header(conn, "location"))
      assert flash(conn, :info) =~ ~r/updated/i
      assert response(conn, 302)
      assert location == ~p"/user/edit"
    end

    test "displays error when invalid input", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = put conn, ~p"/user", %{user: %{username: "R"}}

      assert html_response(conn, 200) =~ "at least 2"
    end
  end

  describe "account deletion" do
    test "phase 1", %{conn: conn} do
      user = insert(:user, email: "test@example.com")
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/user")

      assert response(conn, 302)
      assert flash(conn, :info) =~ ~r/initiated/i
      assert_email_sent(to: [{nil, "test@example.com"}], subject: "Account deletion")
    end

    test "phase 2", %{conn: conn} do
      user = insert(:user)
      token = Accounts.generate_deletion_token(user)

      conn = get(conn, ~p"/user/delete", %{t: token})

      assert html_response(conn, 200) =~ ~r/Yes, delete/
    end

    test "phase 3", %{conn: conn} do
      user = insert(:user)
      token = Accounts.generate_deletion_token(user)

      conn = delete(conn, ~p"/user", %{token: token, confirmed: "1"})

      assert response(conn, 302)
      assert flash(conn, :info) =~ ~r/deleted/i
    end
  end
end
