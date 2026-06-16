defmodule AsciinemaWeb.Features.RecordingsTest do
  use AsciinemaWeb.FeatureCase, async: true

  describe "recording viewing" do
    test "public recording via ID as guest", %{conn: conn} do
      owner = insert(:user)
      asciicast = insert(:asciicast, visibility: :public, user: owner, title: "Public Recording")

      conn
      |> visit(~p"/a/#{asciicast.id}")
      |> assert_has("#cinema")
      |> assert_player_opts()
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
      |> assert_player_opts()
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
      |> assert_player_opts()
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
      |> assert_player_opts()
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
      |> assert_player_opts()
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
      |> assert_player_opts()
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
      |> assert_player_opts()
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
      |> assert_player_opts()
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
      |> assert_has("h1", text: "404 Not Found")
    end

    test "unlisted recording via token as owner", %{conn: conn} do
      owner = insert(:user)
      asciicast = insert(:asciicast, visibility: :unlisted, user: owner, title: "My Recording")

      conn
      |> log_in_user(owner)
      |> visit(~p"/a/#{asciicast.secret_token}")
      |> assert_has("#cinema")
      |> assert_player_opts()
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
      |> assert_has("h1", text: "404 Not Found")
    end

    test "private recording via token as owner", %{conn: conn} do
      owner = insert(:user)

      asciicast =
        insert(:asciicast, visibility: :private, user: owner, title: "Private Recording")

      conn
      |> log_in_user(owner)
      |> visit(~p"/a/#{asciicast.secret_token}")
      |> assert_has("#cinema")
      |> assert_player_opts()
      |> assert_has("h2", text: "Private Recording")
      |> assert_has(".dropdown-item", text: "Settings")
      |> assert_has(".dropdown-item", text: "Delete")
    end

    test "not found", %{conn: conn} do
      conn
      |> visit(~p"/a/nopenopenope")
      |> assert_has("h1", text: "404 Not Found")
    end

    test "page reload with view already counted", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :public, title: "My Recording")

      session =
        conn
        |> visit(~p"/a/#{asciicast}")
        |> assert_has("h2", text: "My Recording")

      [_, view_count_url] = Regex.run(~r/viewCountUrl = "([^"]+)"/, session.conn.resp_body)

      # Simulate the JS POST that would happen when player starts
      view_count_conn = post(session.conn, view_count_url)

      session =
        view_count_conn
        |> Phoenix.ConnTest.recycle()
        |> visit(~p"/a/#{asciicast}")
        |> assert_has("h2", text: "My Recording")

      assert session.conn.resp_body =~ ~s(viewCountUrl = null)
    end

    test "shows more-by section with browse all when more than limit", %{conn: conn} do
      owner = insert(:user, username: "owner")
      asciicast = insert(:asciicast, visibility: :public, user: owner)
      insert_list(6, :asciicast, visibility: :public, user: owner)

      conn
      |> visit(~p"/a/#{asciicast}")
      |> assert_has("section.more-by h2", text: "More recordings by")
      |> assert_has(
        "section.more-by a[href='#{~p"/~owner/recordings"}']",
        text: "Browse all"
      )
    end

    test "hides browse all when at limit", %{conn: conn} do
      owner = insert(:user, username: "owner")
      asciicast = insert(:asciicast, visibility: :public, user: owner)
      insert_list(4, :asciicast, visibility: :public, user: owner)

      conn
      |> visit(~p"/a/#{asciicast}")
      |> assert_has("section.more-by h2", text: "More recordings by")
      |> refute_has(
        "section.more-by a[href='#{~p"/~owner/recordings"}']",
        text: "Browse all"
      )
    end

    test "hides more-by section when no other recordings", %{conn: conn} do
      owner = insert(:user, username: "owner")
      asciicast = insert(:asciicast, visibility: :public, user: owner)

      conn
      |> visit(~p"/a/#{asciicast}")
      |> refute_has("section.more-by")
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

    test "complete flow", %{conn: conn} do
      user = insert(:user)
      asciicast = insert(:asciicast, user: user, title: "Test Recording", visibility: :private)

      conn
      |> log_in_user(user)
      |> visit(~p"/a/#{asciicast}/edit")
      |> fill_in("Title", with: "New Title")
      |> choose("Unlisted")
      |> uncheck("Use adaptive terminal palette")
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

  defp assert_player_opts(session) do
    # Verify the poster option includes snapshot content (factory creates snapshot with "foo" and "bar")
    assert session.conn.resp_body =~ ~r/"poster":"data:text\/plain,[^"]*foo[^"]*bar/

    session
  end
end
