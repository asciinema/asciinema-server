defmodule AsciinemaWeb.Features.StreamsTest do
  use AsciinemaWeb.FeatureCase, async: true

  describe "stream viewing" do
    test "public stream as guest", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      stream = insert(:stream, visibility: :public, user: owner, title: "Public Stream")

      conn
      |> visit(~p"/s/#{stream}")
      |> assert_has("#cinema")
      |> assert_has(".icon-offline")
      |> assert_has("h2", text: "Public Stream")
      |> refute_has("input[value*='asciinema stream -r']")
      |> refute_has(".dropdown-item", text: "Settings")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "unlisted stream as guest", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      stream = insert(:stream, visibility: :unlisted, user: owner, title: "Unlisted Stream")

      conn
      |> visit(~p"/s/#{stream}")
      |> assert_has("#cinema")
      |> assert_has(".icon-offline")
      |> assert_has("h2", text: "Unlisted Stream")
      |> refute_has("input[value*='asciinema stream -r']")
      |> refute_has(".dropdown-item", text: "Settings")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "private stream as guest", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      stream = insert(:stream, visibility: :private, user: owner)

      conn
      |> visit(~p"/s/#{stream}")
      |> assert_has("h1", text: "403 Forbidden")
    end

    test "when owner has streaming disabled as guest", %{conn: conn} do
      owner = insert(:user, streaming_enabled: false)
      stream = insert(:stream, user: owner)

      conn
      |> visit(~p"/s/#{stream}")
      |> assert_has("h1", text: "404 Not Found")
    end

    test "via stream ID as guest", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      stream = insert(:stream, user: owner)

      conn
      |> visit(~p"/s/#{stream.id}")
      |> assert_has("h1", text: "404 Not Found")
    end

    test "public stream as other user", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      viewer = insert(:user)
      stream = insert(:stream, visibility: :public, user: owner, title: "Public Stream")

      conn
      |> log_in_user(viewer)
      |> visit(~p"/s/#{stream}")
      |> assert_has("#cinema")
      |> assert_has(".icon-offline")
      |> assert_has("h2", text: "Public Stream")
      |> refute_has("input[value*='asciinema stream -r']")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "unlisted stream as other user", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      viewer = insert(:user)
      stream = insert(:stream, visibility: :unlisted, user: owner, title: "Unlisted Stream")

      conn
      |> log_in_user(viewer)
      |> visit(~p"/s/#{stream}")
      |> assert_has("#cinema")
      |> assert_has(".icon-offline")
      |> assert_has("h2", text: "Unlisted Stream")
      |> refute_has("input[value*='asciinema stream -r']")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "private stream as other user", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      viewer = insert(:user)
      stream = insert(:stream, visibility: :private, user: owner)

      conn
      |> log_in_user(viewer)
      |> visit(~p"/s/#{stream}")
      |> assert_has("h1", text: "403 Forbidden")
    end

    test "public stream as owner", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      stream = insert(:stream, visibility: :public, user: owner, title: "My Stream")

      conn
      |> log_in_user(owner)
      |> visit(~p"/s/#{stream}")
      |> assert_has("#cinema")
      |> assert_has(".icon-offline")
      |> assert_has("h2", text: "My Stream")
      |> assert_has("input[value*='asciinema stream -r']")
      |> assert_has(".dropdown-item", text: "Settings")
      |> assert_has(".dropdown-item", text: "Delete")
    end

    test "unlisted stream as owner", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      stream = insert(:stream, visibility: :unlisted, user: owner, title: "My Stream")

      conn
      |> log_in_user(owner)
      |> visit(~p"/s/#{stream}")
      |> assert_has("#cinema")
      |> assert_has(".icon-offline")
      |> assert_has("h2", text: "My Stream")
      |> assert_has("input[value*='asciinema stream -r']")
      |> assert_has(".dropdown-item", text: "Settings")
      |> assert_has(".dropdown-item", text: "Delete")
    end

    test "private stream as owner", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      stream = insert(:stream, visibility: :private, user: owner, title: "Private Stream")

      conn
      |> log_in_user(owner)
      |> visit(~p"/s/#{stream}")
      |> assert_has("#cinema")
      |> assert_has(".icon-offline")
      |> assert_has("h2", text: "Private Stream")
      |> assert_has("input[value*='asciinema stream -r']")
      |> assert_has(".dropdown-item", text: "Settings")
      |> assert_has(".dropdown-item", text: "Delete")
    end
  end

  describe "stream editing" do
    test "requires authentication", %{conn: conn} do
      stream = insert(:stream)

      conn
      |> visit(~p"/s/#{stream}/edit")
      |> assert_path(~p"/login/new")
      |> assert_has(".flash", text: "log in first")
    end

    test "requires ownership", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      other_user = insert(:user)
      stream = insert(:stream, user: owner)

      conn
      |> log_in_user(other_user)
      |> visit(~p"/s/#{stream}/edit")
      |> assert_has("h1", text: "403 Forbidden")
    end

    @tag :skip
    # TODO try to re-enable after upgrade of phoenix_test
    test "complete flow", %{conn: conn} do
      user = insert(:user, streaming_enabled: true)
      stream = insert(:stream, user: user, title: "Test Stream", visibility: :private)

      conn
      |> log_in_user(user)
      |> visit(~p"/s/#{stream}/edit")
      |> fill_in("Title", with: "New Title")
      |> choose("Unlisted")
      |> uncheck("Use the actual terminal theme when available")
      |> fill_in("Terminal line height", with: "0.5")
      |> click_button("Save")
      |> refute_has(".flash", text: "updated")
      |> assert_has("div", text: "must be greater than")
      |> fill_in("Terminal line height", with: "1.0")
      |> click_button("Save")
      |> assert_has(".flash", text: "updated")
    end
  end

  describe "stream listing and management" do
    test "complete flow", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      stream1 = insert(:stream, user: owner, title: "Stream One", visibility: :public)
      stream2 = insert(:stream, user: owner, title: "Stream Two", visibility: :private)

      conn
      |> log_in_user(owner)
      |> visit(~p"/user/streams")
      |> assert_has("h2", text: "Your streams")
      |> assert_has("tr", text: "Stream One")
      |> assert_has("tr", text: "Stream Two")
      |> assert_has("a[href='/s/#{stream1.public_token}']")
      |> assert_has("a[href='/s/#{stream2.public_token}']")
      |> click_link("Create new stream")
      |> assert_has(".flash", text: "created")
      |> within("tr:first-child", fn conn ->
        conn |> click_link("Delete")
      end)
      |> assert_has(".flash", text: "deleted")
    end
  end

  describe "stream deletion" do
    test "requires ownership", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      other_user = insert(:user)
      stream = insert(:stream, user: owner)

      conn
      |> log_in_user(other_user)
      |> visit(~p"/s/#{stream}")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "succeeds as owner", %{conn: conn} do
      owner = insert(:user, streaming_enabled: true)
      stream = insert(:stream, user: owner, title: "Stream to Delete")

      conn
      |> log_in_user(owner)
      |> visit(~p"/s/#{stream}")
      |> click_link("Delete")
      |> assert_path(~p"/user/streams")
      |> assert_has(".flash", text: "deleted")
      |> refute_has("a", text: "Stream to Delete")
    end
  end
end
