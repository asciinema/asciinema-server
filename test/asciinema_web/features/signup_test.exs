defmodule AsciinemaWeb.Features.SignupTest do
  use AsciinemaWeb.FeatureCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  describe "signup" do
    test "complete flow", %{conn: conn} do
      conn
      |> visit("/")
      |> click_link("Sign up")
      |> fill_in("E-mail or username", with: "test@example@com")
      |> submit()
      |> assert_has("p", text: "correct email")
      |> fill_in("E-mail or username", with: "test@example.com")
      |> click_button("Log in")
      |> assert_has("h1", text: "Check your inbox")
      |> visit(link_from_email())
      |> assert_has("h1", text: "Verifying link...")
      |> verify_magic_link()
      |> assert_has(".flash", text: "Welcome to")
      |> assert_has("h1", text: "Choose your username")
      |> fill_in("Your username:", with: "---")
      |> click_button("Continue")
      |> assert_has("p", text: "only letters")
      |> fill_in("Your username:", with: "foobar")
      |> click_button("Continue")
      |> assert_path("/~foobar")
      |> assert_has("h1", text: "Joined on")
    end

    test "without setting username", %{conn: conn} do
      conn
      |> visit("/")
      |> click_link("Sign up")
      |> fill_in("E-mail or username", with: "test@example.com")
      |> click_button("Log in")
      |> visit(link_from_email())
      |> verify_magic_link()
      |> click_link("I'll do it later")
      |> assert_has("h1", text: "Joined on")
    end

    test "duplicate emails", %{conn: conn} do
      conn
      |> visit("/")
      |> click_link("Sign up")
      |> fill_in("E-mail or username", with: "test@example.com")
      |> submit()
      |> assert_has("h1", text: "Check your inbox")

      first_link = link_from_email()

      conn
      |> visit("/")
      |> click_link("Sign up")
      |> fill_in("E-mail or username", with: "test@example.com")
      |> submit()
      |> visit(link_from_email())
      |> verify_magic_link()
      |> assert_has(".flash", text: "Welcome to")

      conn
      |> visit(first_link)
      |> assert_has("h1", text: "Verifying link...")
      |> verify_magic_link()
      |> assert_has(".flash", text: "already")
      |> assert_path("/login/new")
    end

    test "invalid email link", %{conn: conn} do
      conn
      |> visit("/")
      |> click_link("Sign up")
      |> fill_in("E-mail or username", with: "test@example.com")
      |> click_button("Log in")
      |> visit(String.replace(link_from_email(), ~r{t=.+}, "t=nope"))
      |> assert_has("h1", text: "Verifying link...")
      |> verify_magic_link()
      |> refute_has(".flash", text: "Welcome")
      |> assert_has(".flash", text: "Invalid sign-up link")
    end
  end
end
