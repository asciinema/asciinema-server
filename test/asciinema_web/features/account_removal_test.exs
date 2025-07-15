defmodule AsciinemaWeb.Features.AccountRemovalTest do
  use AsciinemaWeb.FeatureCase, async: true
  use Oban.Testing, repo: Asciinema.Repo
  import Swoosh.TestAssertions

  describe "account removal" do
    test "complete flow", %{conn: conn} do
      user = insert(:user, username: "foobar")

      conn
      |> log_in_user(user)
      |> visit("/")
      |> click_link("Settings")
      |> click_link("Delete my account")
      |> assert_has(".flash", text: "check your inbox")
      |> visit(link_from_email())
      |> assert_has("p", text: "will permanently delete")
      |> click_button("Yes, delete my account")
      |> assert_has(".flash", text: "Account deleted")
      |> assert_path("/")

      conn
      |> visit("/")
      |> click_link("Log in")
      |> fill_in("E-mail or username", with: "foobar")
      |> click_button("Log in")
      |> assert_has("p", text: "No user found")

      assert_no_email_sent()
    end
  end
end
