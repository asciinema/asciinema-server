defmodule AsciinemaWeb.Features.HomeTest do
  use AsciinemaWeb.FeatureCase, async: true
  import Asciinema.Factory

  describe "home page sections" do
    test "shows only public live streams, featured recordings, and popular recordings", %{
      conn: conn
    } do
      insert(:stream, visibility: :public, title: "Public Live Stream", live: true)
      insert(:stream, visibility: :unlisted, title: "Unlisted Live Stream", live: true)

      insert(:asciicast, visibility: :public, featured: true, title: "Featured Recording")
      insert(:asciicast, visibility: :public, featured: false, title: "Normal Recording")

      insert(:asciicast,
        visibility: :private,
        featured: true,
        title: "Private Featured Recording"
      )

      popular = insert(:asciicast, visibility: :public, title: "Popular Recording")
      insert(:asciicast_stats, asciicast_id: popular.id, popularity_score: 5.0)

      unlisted_popular = insert(:asciicast, visibility: :unlisted, title: "Unlisted Popular")
      insert(:asciicast_stats, asciicast_id: unlisted_popular.id, popularity_score: 5.0)

      conn
      |> visit(~p"/")
      |> assert_has("h2", text: "Live streams")
      |> assert_has("a", text: "Public Live Stream")
      |> refute_has("a", text: "Unlisted Live Stream")
      |> assert_has("h2", text: "Featured recordings")
      |> assert_has("a", text: "Featured Recording")
      |> refute_has("a", text: "Normal Recording")
      |> refute_has("a", text: "Private Featured Recording")
      |> assert_has("h2", text: "Popular recordings")
      |> assert_has("a", text: "Popular Recording")
      |> refute_has("a", text: "Unlisted Popular")
    end

    test "shows browse all links when there are more than two items", %{conn: conn} do
      Enum.each(1..3, fn index ->
        insert(:stream, visibility: :public, title: "Live Stream #{index}", live: true)
      end)

      Enum.each(1..3, fn index ->
        insert(:asciicast, visibility: :public, featured: true, title: "Featured #{index}")
      end)

      Enum.each(1..3, fn index ->
        asciicast = insert(:asciicast, visibility: :public, title: "Popular #{index}")
        insert(:asciicast_stats, asciicast_id: asciicast.id, popularity_score: 5.0)
      end)

      conn
      |> visit(~p"/")
      |> assert_has("a[href='#{~p"/explore/streams/live"}']", text: "Browse all")
      |> assert_has("a[href='#{~p"/explore/recordings/featured"}']", text: "Browse all")
      |> assert_has("a[href='#{~p"/explore/recordings/popular"}']", text: "Browse all")
    end
  end
end
