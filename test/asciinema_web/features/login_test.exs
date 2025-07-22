defmodule AsciinemaWeb.Features.LoginTest do
  use AsciinemaWeb.FeatureCase, async: true
  use Oban.Testing, repo: Asciinema.Repo
  import Swoosh.TestAssertions

  describe "login" do
    test "complete flow via email", %{conn: conn} do
      insert(:user, username: "foobar", email: "test@example.com")

      conn
      |> visit("/")
      |> click_link("Log in")
      |> fill_in("E-mail or username", with: "test@example.com")
      |> click_button("Log in")
      |> assert_has("h1", text: "Check your inbox")
      |> visit(link_from_email())
      |> assert_has("h1", text: "Verifying link...")
      |> verify_magic_link()
      |> assert_path("/~foobar")
      |> assert_has(".flash", text: "Welcome back")
      |> assert_has("h1", text: "foobar")
    end

    test "complete flow via username", %{conn: conn} do
      insert(:user, username: "foobar", email: "test@example.com")

      conn
      |> visit("/")
      |> click_link("Log in")
      |> fill_in("E-mail or username", with: "foobar")
      |> click_button("Log in")
      |> assert_has("h1", text: "Check your inbox")
      |> visit(link_from_email())
      |> assert_has("h1", text: "Verifying link...")
      |> verify_magic_link()
      |> assert_path("/~foobar")
      |> assert_has(".flash", text: "Welcome back")
      |> assert_has("h1", text: "foobar")
    end

    test "username not set yet", %{conn: conn} do
      insert(:user, username: nil, email: "test@example.com")

      conn
      |> visit("/")
      |> click_link("Log in")
      |> fill_in("E-mail or username", with: "test@example.com")
      |> click_button("Log in")
      |> visit(link_from_email())
      |> verify_magic_link()
      |> assert_has(".flash", text: "Welcome back")
      |> assert_has("h1", text: "Choose your username")
    end

    test "invalid email link", %{conn: conn} do
      insert(:user, email: "test@example.com")

      conn
      |> visit("/")
      |> click_link("Log in")
      |> fill_in("E-mail or username", with: "test@example.com")
      |> click_button("Log in")
      |> visit(String.replace(link_from_email(), ~r{t=.+}, "t=nope"))
      |> assert_has("h1", text: "Verifying link...")
      |> verify_magic_link()
      |> refute_has(".flash", text: "Welcome")
      |> assert_has(".flash", text: "Invalid login link")
    end

    test "username not found", %{conn: conn} do
      conn
      |> visit("/")
      |> click_link("Log in")
      |> fill_in("E-mail or username", with: "foobar")
      |> click_button("Log in")
      |> assert_has("p", text: "No user found")

      assert_no_email_sent()
    end

    test "user deleted after sending login email", %{conn: conn} do
      user = insert(:user, email: "test@example.com")

      session =
        conn
        |> visit("/")
        |> click_link("Log in")
        |> fill_in("E-mail or username", with: "test@example.com")
        |> click_button("Log in")

      Asciinema.delete_user!(user)

      session
      |> visit(link_from_email())
      |> verify_magic_link()
      |> assert_has(".flash", text: "This account has been removed")
    end
  end
end
