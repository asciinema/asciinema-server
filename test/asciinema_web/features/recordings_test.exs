defmodule AsciinemaWeb.Features.RecordingsTest do
  use AsciinemaWeb.FeatureCase, async: true

  describe "exploring" do
    test "auto, public, featured", %{conn: conn} do
      insert(:asciicast, visibility: :public, featured: true, title: "Featured stuff")
      insert(:asciicast, visibility: :public, title: "Good stuff")
      insert(:asciicast, visibility: :unlisted, title: "Unlisted stuff")
      insert(:asciicast, visibility: :private, title: "Private stuff")

      conn
      |> visit(~p"/")
      |> click_link("Explore")
      |> assert_has("a", text: "Featured stuff")
      |> refute_has("a", text: "Good stuff")
      |> refute_has("a", text: "Unlisted stuff")
      |> refute_has("a", text: "Private stuff")
      |> click_link("all public")
      |> assert_has("a", text: "Featured stuff")
      |> assert_has("a", text: "Good stuff")
      |> refute_has("a", text: "Unlisted stuff")
      |> refute_has("a", text: "Private stuff")
      |> click_link("featured")
      |> assert_has("a", text: "Featured stuff")
      |> refute_has("a", text: "Good stuff")
      |> refute_has("a", text: "Unlisted stuff")
      |> refute_has("a", text: "Private stuff")
    end
  end

  describe "recording viewing" do
    test "public recording via ID as guest", %{conn: conn} do
      owner = insert(:user)
      asciicast = insert(:asciicast, visibility: :public, user: owner, title: "Public Recording")

      conn
      |> visit(~p"/a/#{asciicast.id}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "Public Recording")
      |> refute_has(".dropdown-item", text: "Settings")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "public recording via token as guest", %{conn: conn} do
      owner = insert(:user)
      asciicast = insert(:asciicast, visibility: :public, user: owner, title: "Public Recording")

      conn
      |> visit(~p"/a/#{asciicast.secret_token}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "Public Recording")
      |> refute_has(".dropdown-item", text: "Settings")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "unlisted recording via ID as guest", %{conn: conn} do
      owner = insert(:user)

      asciicast =
        insert(:asciicast, visibility: :unlisted, user: owner, title: "Unlisted Recording")

      conn
      |> visit(~p"/a/#{asciicast.id}")
      |> assert_has("h1", text: "404 Not Found")
    end

    test "unlisted recording via token as guest", %{conn: conn} do
      owner = insert(:user)

      asciicast =
        insert(:asciicast, visibility: :unlisted, user: owner, title: "Unlisted Recording")

      conn
      |> visit(~p"/a/#{asciicast.secret_token}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "Unlisted Recording")
      |> refute_has(".dropdown-item", text: "Settings")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "private recording via ID as guest", %{conn: conn} do
      owner = insert(:user)
      asciicast = insert(:asciicast, visibility: :private, user: owner)

      conn
      |> visit(~p"/a/#{asciicast.id}")
      |> assert_has("h1", text: "404 Not Found")
    end

    test "private recording via token as guest", %{conn: conn} do
      owner = insert(:user)
      asciicast = insert(:asciicast, visibility: :private, user: owner)

      conn
      |> visit(~p"/a/#{asciicast.secret_token}")
      |> assert_has("h1", text: "403 Forbidden")
    end

    test "public recording via ID as other user", %{conn: conn} do
      owner = insert(:user)
      viewer = insert(:user)
      asciicast = insert(:asciicast, visibility: :public, user: owner, title: "Public Recording")

      conn
      |> log_in_user(viewer)
      |> visit(~p"/a/#{asciicast.id}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "Public Recording")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "public recording via token as other user", %{conn: conn} do
      owner = insert(:user)
      viewer = insert(:user)
      asciicast = insert(:asciicast, visibility: :public, user: owner, title: "Public Recording")

      conn
      |> log_in_user(viewer)
      |> visit(~p"/a/#{asciicast.secret_token}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "Public Recording")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "unlisted recording via ID as other user", %{conn: conn} do
      owner = insert(:user)
      viewer = insert(:user)

      asciicast =
        insert(:asciicast, visibility: :unlisted, user: owner, title: "Unlisted Recording")

      conn
      |> log_in_user(viewer)
      |> visit(~p"/a/#{asciicast.id}")
      |> assert_has("h1", text: "404 Not Found")
    end

    test "unlisted recording via token as other user", %{conn: conn} do
      owner = insert(:user)
      viewer = insert(:user)

      asciicast =
        insert(:asciicast, visibility: :unlisted, user: owner, title: "Unlisted Recording")

      conn
      |> log_in_user(viewer)
      |> visit(~p"/a/#{asciicast.secret_token}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "Unlisted Recording")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "private recording via ID as other user", %{conn: conn} do
      owner = insert(:user)
      viewer = insert(:user)
      asciicast = insert(:asciicast, visibility: :private, user: owner)

      conn
      |> log_in_user(viewer)
      |> visit(~p"/a/#{asciicast.id}")
      |> assert_has("h1", text: "404 Not Found")
    end

    test "private recording via token as other user", %{conn: conn} do
      owner = insert(:user)
      viewer = insert(:user)
      asciicast = insert(:asciicast, visibility: :private, user: owner)

      conn
      |> log_in_user(viewer)
      |> visit(~p"/a/#{asciicast.secret_token}")
      |> assert_has("h1", text: "403 Forbidden")
    end

    test "public recording via ID as owner", %{conn: conn} do
      owner = insert(:user)
      asciicast = insert(:asciicast, visibility: :public, user: owner, title: "My Recording")

      conn
      |> log_in_user(owner)
      |> visit(~p"/a/#{asciicast.id}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "My Recording")
      |> assert_has(".dropdown-item", text: "Settings")
      |> assert_has(".dropdown-item", text: "Delete")
    end

    test "public recording via token as owner", %{conn: conn} do
      owner = insert(:user)
      asciicast = insert(:asciicast, visibility: :public, user: owner, title: "My Recording")

      conn
      |> log_in_user(owner)
      |> visit(~p"/a/#{asciicast.secret_token}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "My Recording")
      |> assert_has(".dropdown-item", text: "Settings")
      |> assert_has(".dropdown-item", text: "Delete")
    end

    test "unlisted recording via ID as owner", %{conn: conn} do
      owner = insert(:user)
      asciicast = insert(:asciicast, visibility: :unlisted, user: owner, title: "My Recording")

      conn
      |> log_in_user(owner)
      |> visit(~p"/a/#{asciicast.id}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "My Recording")
      |> assert_has(".dropdown-item", text: "Settings")
      |> assert_has(".dropdown-item", text: "Delete")
    end

    test "unlisted recording via token as owner", %{conn: conn} do
      owner = insert(:user)
      asciicast = insert(:asciicast, visibility: :unlisted, user: owner, title: "My Recording")

      conn
      |> log_in_user(owner)
      |> visit(~p"/a/#{asciicast.secret_token}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "My Recording")
      |> assert_has(".dropdown-item", text: "Settings")
      |> assert_has(".dropdown-item", text: "Delete")
    end

    test "private recording via ID as owner", %{conn: conn} do
      owner = insert(:user)

      asciicast =
        insert(:asciicast, visibility: :private, user: owner, title: "Private Recording")

      conn
      |> log_in_user(owner)
      |> visit(~p"/a/#{asciicast.id}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "Private Recording")
      |> assert_has(".dropdown-item", text: "Settings")
      |> assert_has(".dropdown-item", text: "Delete")
    end

    test "private recording via token as owner", %{conn: conn} do
      owner = insert(:user)

      asciicast =
        insert(:asciicast, visibility: :private, user: owner, title: "Private Recording")

      conn
      |> log_in_user(owner)
      |> visit(~p"/a/#{asciicast.secret_token}")
      |> assert_has("#cinema")
      |> assert_has("h2", text: "Private Recording")
      |> assert_has(".dropdown-item", text: "Settings")
      |> assert_has(".dropdown-item", text: "Delete")
    end
  end

  describe "recording editing" do
    test "requires authentication", %{conn: conn} do
      asciicast = insert(:asciicast)

      conn
      |> visit(~p"/a/#{asciicast}/edit")
      |> assert_path(~p"/login/new")
      |> assert_has(".flash", text: "log in first")
    end

    test "requires ownership", %{conn: conn} do
      owner = insert(:user)
      other_user = insert(:user)
      asciicast = insert(:asciicast, user: owner)

      conn
      |> log_in_user(other_user)
      |> visit(~p"/a/#{asciicast}/edit")
      |> assert_has("h1", text: "403 Forbidden")
    end

    @tag :skip
    # TODO try to re-enable after upgrade of phoenix_test
    test "complete flow", %{conn: conn} do
      user = insert(:user)
      asciicast = insert(:asciicast, user: user, title: "Test Recording", visibility: :private)

      conn
      |> log_in_user(user)
      |> visit(~p"/a/#{asciicast}/edit")
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

  describe "recording deletion" do
    test "requires ownership", %{conn: conn} do
      owner = insert(:user)
      other_user = insert(:user)
      asciicast = insert(:asciicast, user: owner)

      conn
      |> log_in_user(other_user)
      |> visit(~p"/a/#{asciicast}")
      |> refute_has(".dropdown-item", text: "Delete")
    end

    test "succeeds as owner", %{conn: conn} do
      owner = insert(:user)
      asciicast = insert(:asciicast, user: owner, title: "Recording to Delete")

      conn
      |> log_in_user(owner)
      |> visit(~p"/a/#{asciicast}")
      |> click_link("Delete")
      |> assert_has(".flash", text: "deleted")
      |> refute_has("a", text: "Recording to Delete")
      |> visit(~p"/a/#{asciicast}")
      |> assert_has("h1", text: "404 Not Found")
    end
  end
end
