defmodule AsciinemaWeb.Features.ProfileTest do
  use AsciinemaWeb.FeatureCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  defp insert_profile_recordings(user) do
    insert(:asciicast, user: user, visibility: :public, title: "Public Recording")
    insert(:asciicast, user: user, visibility: :unlisted, title: "Unlisted Recording")
    insert(:asciicast, user: user, visibility: :private, title: "Private Recording")
  end

  defp insert_profile_streams(user) do
    insert(:stream, user: user, visibility: :public, title: "Public Stream", live: true)
    insert(:stream, user: user, visibility: :unlisted, title: "Unlisted Stream", live: true)
    insert(:stream, user: user, visibility: :private, title: "Private Stream", live: true)
  end

  defp insert_upcoming_stream(user, visibility \\ :public) do
    hour_from_now = DateTime.shift(DateTime.utc_now(), hour: 1)

    insert(:stream,
      user: user,
      visibility: visibility,
      title: "Upcoming Stream",
      live: false,
      next_start_at: hour_from_now
    )
  end

  describe "profile viewing" do
    test "as guest", %{conn: conn} do
      user = insert(:user, username: "foobar", name: "Test User")
      insert_profile_recordings(user)
      insert_profile_streams(user)
      insert_upcoming_stream(user)

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
      |> assert_has("a", text: "Upcoming Stream")
    end

    test "as other user", %{conn: conn} do
      viewer = insert(:user, username: "viewer")
      user = insert(:user, username: "foobar", name: "Profile Owner")
      insert_profile_recordings(user)
      insert_profile_streams(user)
      insert_upcoming_stream(user)

      conn
      |> log_in_user(viewer)
      |> visit(~p"/~foobar")
      |> assert_has("h1", text: "Profile Owner")
      |> refute_has("a", text: "Edit profile")
      |> assert_has("a", text: "Public Recording")
      |> refute_has("a", text: "Unlisted Recording")
      |> refute_has("a", text: "Private Recording")
      |> assert_has("a", text: "Public Stream")
      |> refute_has("a", text: "Unlisted Stream")
      |> refute_has("a", text: "Private Stream")
      |> assert_has("a", text: "Upcoming Stream")
    end

    test "as owner", %{conn: conn} do
      user = insert(:user, username: "foobar", name: "Test User")
      insert_profile_recordings(user)
      insert_profile_streams(user)
      insert_upcoming_stream(user, :private)

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
      |> assert_has("a", text: "Upcoming Stream")
    end

    test "as owner with no recordings or streams", %{conn: conn} do
      user = insert(:user, username: "empty", streaming_enabled: true)

      conn
      |> log_in_user(user)
      |> visit(~p"/~empty")
      |> assert_has("h2", text: "Your live streams")
      |> assert_has("p", text: "You have no live streams.")
      |> refute_has("h2", text: "Your upcoming streams")
      |> assert_has("h2", text: "Your recordings")
      |> assert_has("p", text: "You have no recordings.")
    end

    test "as other user with no recordings or streams", %{conn: conn} do
      viewer = insert(:user, username: "viewer")
      insert(:user, username: "empty", streaming_enabled: true)

      conn
      |> log_in_user(viewer)
      |> visit(~p"/~empty")
      |> refute_has("h2", text: "empty's live streams")
      |> refute_has("h2", text: "empty's upcoming streams")
      |> assert_has("h2", text: "empty's recordings")
      |> assert_has("p", text: "empty has no public recordings.")
    end

    test "as other user with streaming disabled", %{conn: conn} do
      viewer = insert(:user, username: "viewer")
      user = insert(:user, username: "nostreams", streaming_enabled: false)
      insert(:asciicast, user: user, visibility: :public, title: "Public Recording")
      insert(:stream, user: user, visibility: :public, title: "Public Stream", live: true)
      insert_upcoming_stream(user)

      conn
      |> log_in_user(viewer)
      |> visit(~p"/~nostreams")
      |> assert_has("h2", text: "nostreams's live streams")
      |> refute_has("h2", text: "nostreams's upcoming streams")
      |> refute_has("a", text: "Public Stream")
      |> refute_has("a", text: "Upcoming Stream")
      |> assert_has("a", text: "Public Recording")
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
      user = insert(:user, username: "foobar", name: "Test User")

      conn
      |> log_in_user(user)
      |> visit("/")
      |> click_link("Settings")
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
