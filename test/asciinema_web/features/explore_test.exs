defmodule AsciinemaWeb.Features.ExploreTest do
  use AsciinemaWeb.FeatureCase, async: true

  describe "main explore page" do
    test "shows featured and recent recordings, live and upcoming streams", %{conn: conn} do
      insert(:asciicast, visibility: :public, featured: true, title: "Featured Recording")
      insert(:asciicast, visibility: :public, title: "Recent Recording")
      insert(:asciicast, visibility: :unlisted, title: "Unlisted Recording")
      insert(:asciicast, visibility: :private, title: "Private Recording")

      insert(:stream, visibility: :public, title: "Live Stream", live: true)
      insert(:stream, visibility: :unlisted, title: "Unlisted Live Stream", live: true)
      insert(:stream, visibility: :private, title: "Private Live Stream", live: true)

      hour_from_now = DateTime.shift(DateTime.utc_now(), hour: 1)

      insert(:stream,
        visibility: :public,
        title: "Upcoming Stream",
        live: false,
        next_start_at: hour_from_now
      )

      insert(:stream,
        visibility: :unlisted,
        title: "Unlisted Upcoming Stream",
        live: false,
        next_start_at: hour_from_now
      )

      insert(:stream,
        visibility: :private,
        title: "Private Upcoming Stream",
        live: false,
        next_start_at: hour_from_now
      )

      conn
      |> visit(~p"/explore")
      |> assert_has("a", text: "Featured Recording")
      |> assert_has("a", text: "Recent Recording")
      |> refute_has("a", text: "Unlisted Recording")
      |> refute_has("a", text: "Private Recording")
      |> assert_has("a", text: "Live Stream")
      |> refute_has("a", text: "Unlisted Live Stream")
      |> refute_has("a", text: "Private Live Stream")
      |> assert_has("a", text: "Upcoming Stream")
      |> refute_has("a", text: "Unlisted Upcoming Stream")
      |> refute_has("a", text: "Private Upcoming Stream")
    end
  end

  describe "featured recordings" do
    test "shows only featured", %{conn: conn} do
      insert(:asciicast, visibility: :public, featured: true, title: "Featured stuff")
      insert(:asciicast, visibility: :public, featured: true, title: "Featured more")
      insert(:asciicast, visibility: :public, featured: true, title: "Featured extra")
      insert(:asciicast, visibility: :public, title: "Good stuff")
      insert(:asciicast, visibility: :unlisted, title: "Unlisted stuff")
      insert(:asciicast, visibility: :private, title: "Private stuff")

      conn
      |> visit(~p"/explore")
      |> click_link("a[href='#{~p"/explore/recordings/featured"}']", "Browse all")
      |> assert_has("a", text: "Featured stuff")
      |> refute_has("a", text: "Good stuff")
      |> refute_has("a", text: "Unlisted stuff")
      |> refute_has("a", text: "Private stuff")
    end
  end

  describe "recent recordings" do
    test "shows all public recordings", %{conn: conn} do
      insert(:asciicast, visibility: :public, featured: true, title: "Featured stuff")
      insert(:asciicast, visibility: :public, title: "Good stuff")
      insert(:asciicast, visibility: :public, title: "More good stuff")
      insert(:asciicast, visibility: :unlisted, title: "Unlisted stuff")
      insert(:asciicast, visibility: :private, title: "Private stuff")
      insert_list(10, :asciicast, visibility: :public)

      conn
      |> visit(~p"/explore")
      |> click_link("a[href='#{~p"/explore/recordings/recent"}']", "Browse all")
      |> assert_has("a", text: "Featured stuff")
      |> assert_has("a", text: "Good stuff")
      |> refute_has("a", text: "Unlisted stuff")
      |> refute_has("a", text: "Private stuff")
    end
  end

  describe "live streams" do
    test "shows only public live streams", %{conn: conn} do
      insert(:stream, visibility: :public, title: "Public Live Stream", live: true)
      insert(:stream, visibility: :public, title: "Public Live Stream 2", live: true)
      insert(:stream, visibility: :public, title: "Public Live Stream 3", live: true)
      insert(:stream, visibility: :unlisted, title: "Unlisted Live Stream", live: true)
      insert(:stream, visibility: :private, title: "Private Live Stream", live: true)
      insert(:stream, visibility: :public, title: "Offline Stream", live: false)

      conn
      |> visit(~p"/explore")
      |> click_link("a[href='#{~p"/explore/streams/live"}']", "Browse all")
      |> assert_has("a", text: "Public Live Stream")
      |> refute_has("a", text: "Unlisted Live Stream")
      |> refute_has("a", text: "Private Live Stream")
      |> refute_has("a", text: "Offline Stream")
    end
  end

  describe "upcoming streams" do
    test "shows only public upcoming streams", %{conn: conn} do
      hour_from_now = DateTime.shift(DateTime.utc_now(), hour: 1)

      insert(:stream,
        visibility: :public,
        title: "Public Upcoming Stream",
        live: false,
        next_start_at: hour_from_now
      )

      insert(:stream,
        visibility: :public,
        title: "Public Upcoming Stream 2",
        live: false,
        next_start_at: hour_from_now
      )

      insert(:stream,
        visibility: :public,
        title: "Public Upcoming Stream 3",
        live: false,
        next_start_at: hour_from_now
      )

      insert(:stream,
        visibility: :unlisted,
        title: "Unlisted Upcoming Stream",
        live: false,
        next_start_at: hour_from_now
      )

      insert(:stream,
        visibility: :private,
        title: "Private Upcoming Stream",
        live: false,
        next_start_at: hour_from_now
      )

      insert(:stream, visibility: :public, title: "Live Stream", live: true)
      insert(:stream, visibility: :public, title: "No Schedule Stream", live: false)

      conn
      |> visit(~p"/explore")
      |> click_link("a[href='#{~p"/explore/streams/upcoming"}']", "Browse all")
      |> assert_has("a", text: "Public Upcoming Stream")
      |> refute_has("a", text: "Unlisted Upcoming Stream")
      |> refute_has("a", text: "Private Upcoming Stream")
      |> refute_has("a", text: "Live Stream")
      |> refute_has("a", text: "No Schedule Stream")
    end
  end
end
