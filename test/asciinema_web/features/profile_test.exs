defmodule AsciinemaWeb.Features.ProfileTest do
  use AsciinemaWeb.FeatureCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  describe "profile viewing" do
    test "as guest", %{conn: conn} do
      user = insert(:user, username: "foobar", name: "Test User")
      insert(:asciicast, user: user, visibility: :public, title: "Public Recording")
      insert(:asciicast, user: user, visibility: :unlisted, title: "Unlisted Recording")
      insert(:asciicast, user: user, visibility: :private, title: "Private Recording")
      insert(:stream, user: user, visibility: :public, title: "Public Stream", live: true)
      insert(:stream, user: user, visibility: :unlisted, title: "Unlisted Stream", live: true)
      insert(:stream, user: user, visibility: :private, title: "Private Stream", live: true)

      conn
      |> visit(~p"/~foobar")
      |> assert_has("h1", text: "Test User")
      |> refute_has("a", text: "Settings")
      |> assert_has("a", text: "Public Recording")
      |> refute_has("a", text: "Unlisted Recording")
      |> refute_has("a", text: "Private Recording")
      |> assert_has("a", text: "Public Stream")
      |> refute_has("a", text: "Unlisted Stream")
      |> refute_has("a", text: "Private Stream")
    end

    test "as other user", %{conn: conn} do
      viewer = insert(:user, username: "viewer")
      user = insert(:user, username: "foobar", name: "Profile Owner")
      insert(:asciicast, user: user, visibility: :public, title: "Public Recording")
      insert(:asciicast, user: user, visibility: :unlisted, title: "Unlisted Recording")
      insert(:asciicast, user: user, visibility: :private, title: "Private Recording")
      insert(:stream, user: user, visibility: :public, title: "Public Stream", live: true)
      insert(:stream, user: user, visibility: :unlisted, title: "Unlisted Stream", live: true)
      insert(:stream, user: user, visibility: :private, title: "Private Stream", live: true)

      conn
      |> log_in_user(viewer)
      |> visit(~p"/~foobar")
      |> assert_has("h1", text: "Profile Owner")
      |> assert_has("a", text: "Public Recording")
      |> refute_has("a", text: "Unlisted Recording")
      |> refute_has("a", text: "Private Recording")
      |> assert_has("a", text: "Public Stream")
      |> refute_has("a", text: "Unlisted Stream")
      |> refute_has("a", text: "Private Stream")
    end

    test "as owner", %{conn: conn} do
      user = insert(:user, username: "foobar", name: "Test User")
      insert(:asciicast, user: user, visibility: :public, title: "Public Recording")
      insert(:asciicast, user: user, visibility: :unlisted, title: "Unlisted Recording")
      insert(:asciicast, user: user, visibility: :private, title: "Private Recording")
      insert(:stream, user: user, visibility: :public, title: "Public Stream", live: true)
      insert(:stream, user: user, visibility: :unlisted, title: "Unlisted Stream", live: true)
      insert(:stream, user: user, visibility: :private, title: "Private Stream", live: true)

      conn
      |> log_in_user(user)
      |> visit(~p"/~foobar")
      |> assert_has("h1", text: "Test User")
      |> assert_has("a", text: "Settings")
      |> assert_has("a", text: "Public Recording")
      |> assert_has("a", text: "Unlisted Recording")
      |> assert_has("a", text: "Private Recording")
      |> assert_has("a", text: "Public Stream")
      |> assert_has("a", text: "Unlisted Stream")
      |> assert_has("a", text: "Private Stream")
    end

    test "by ID", %{conn: conn} do
      user = insert(:user, username: "foobar", name: "Test User")

      conn
      |> visit(~p"/u/#{user.id}")
      |> assert_has("h1", text: "Test User")
    end
  end

  describe "profile editing" do
    test "requires authentication", %{conn: conn} do
      conn
      |> visit(~p"/user/edit")
      |> assert_path(~p"/login/new")
      |> assert_has(".flash", text: "log in first")
    end

    test "complete flow", %{conn: conn} do
      user = insert(:user, username: "foobar", name: "Test User", email: "test@example.com")

      conn
      |> log_in_user(user)
      |> visit(~p"/user/edit")
      |> fill_in("Email", with: "new@example@com")
      |> within("#account-form", fn conn ->
        conn |> click_button("Update")
      end)
      |> assert_has("div", text: "has invalid format")
      |> fill_in("Email", with: "new@example.com")
      |> within("#account-form", fn conn ->
        conn |> click_button("Update")
      end)
      |> assert_has(".flash", text: "updated")
      |> fill_in("Display name", with: "New Name")
      |> fill_in("Username", with: "---")
      |> within("#profile-form", fn conn ->
        conn |> click_button("Update")
      end)
      |> assert_has("div", text: "has invalid format")
      |> fill_in("Username", with: "bazqux")
      |> within("#profile-form", fn conn ->
        conn |> click_button("Update")
      end)
      |> assert_has(".flash", text: "updated")
      |> choose("#user_default_recording_visibility_unlisted", "Unlisted")
      |> select("Terminal theme", option: "Solarized Dark")
      |> within("#defaults-form", fn conn ->
        conn |> click_button("Update")
      end)
      |> assert_has(".flash", text: "updated")
    end
  end
end
