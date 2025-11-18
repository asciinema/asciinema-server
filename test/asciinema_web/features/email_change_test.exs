defmodule AsciinemaWeb.Features.EmailChangeTest do
  use AsciinemaWeb.FeatureCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  describe "email address change" do
    test "complete flow", %{conn: conn} do
      user = insert(:user, username: "foobar", email: "test@example.com")

      conn
      |> log_in_user(user)
      |> visit("/")
      |> click_link("Settings")
      |> fill_in("Email", with: "new@example@com")
      |> within("#account-form", fn conn ->
        conn |> click_button("Change")
      end)
      |> assert_has("small", text: "Invalid address")
      |> fill_in("Email", with: "new@example.com")
      |> within("#account-form", fn conn ->
        conn |> click_button("Change")
      end)
      |> assert_has("small", text: "To finalize the email address change")
      |> visit(link_from_email())
      |> assert_has(".flash", text: "Email address has been changed")
      |> assert_path(~p"/user/edit")
      |> assert_has("input", value: "new@example.com")
    end
  end
end
