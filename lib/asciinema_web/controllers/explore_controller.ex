defmodule AsciinemaWeb.ExploreController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Recordings, Streaming}

  def show(conn, _params) do
    live_streams = fetch_live_streams()
    upcoming_streams = fetch_upcoming_streams()
    featured_asciicasts = fetch_featured_asciicasts()
    popular_asciicasts = fetch_popular_asciicasts()

    recent_asciicasts =
      fetch_recent_asciicasts([
        live_streams,
        upcoming_streams,
        featured_asciicasts,
        popular_asciicasts
      ])

    assigns = [
      page_title: "Explore",
      live_streams: live_streams,
      upcoming_streams: upcoming_streams,
      featured_asciicasts: featured_asciicasts,
      popular_asciicasts: popular_asciicasts,
      recent_asciicasts: recent_asciicasts
    ]

    render(conn, "show.html", assigns)
  end

  defp fetch_live_streams do
    [:public, :live]
    |> Streaming.query(:recently_started)
    |> list_streams(2)
  end

  defp fetch_upcoming_streams do
    [:public, :upcoming]
    |> Streaming.query(:soonest)
    |> list_streams(2)
  end

  defp fetch_featured_asciicasts do
    :featured
    |> Recordings.query(:random)
    |> list_asciicasts(2)
  end

  @popular_pool_size 50
  @popular_limit 2

  defp fetch_popular_asciicasts do
    seed = div(DateTime.to_unix(DateTime.utc_now()), 60)

    asciicasts =
      :popular
      |> Recordings.query(:popularity)
      |> Recordings.list(@popular_pool_size)
      |> Enum.sort_by(fn asciicast -> :erlang.phash2({asciicast.id, seed}) end)

    %{
      items: Enum.take(asciicasts, @popular_limit),
      has_more: length(asciicasts) > @popular_limit
    }
  end

  defp fetch_recent_asciicasts(earlier_sections) do
    used_rows =
      Enum.reduce(earlier_sections, 0, fn section, acc ->
        case section do
          %{items: []} -> acc
          %{items: _} -> acc + 1
        end
      end)

    limit = (5 - used_rows) * 2

    :public
    |> Recordings.query(:date)
    |> list_asciicasts(limit)
  end

  def featured_recordings(conn, params) do
    asciicasts =
      :featured
      |> Recordings.query(:date)
      |> Recordings.paginate(params["page"], 14, pagination_opts(conn))

    assigns = [
      page_title: "Featured recordings",
      asciicasts: asciicasts
    ]

    render(conn, "featured_recordings.html", assigns)
  end

  def popular_recordings(conn, params) do
    asciicasts =
      :popular
      |> Recordings.query(:popularity)
      |> Recordings.paginate(params["page"], 14, pagination_opts(conn))

    assigns = [
      page_title: "Popular recordings",
      asciicasts: asciicasts
    ]

    render(conn, "popular_recordings.html", assigns)
  end

  def recent_recordings(conn, params) do
    asciicasts =
      :public
      |> Recordings.query(:date)
      |> Recordings.paginate(params["page"], 14, pagination_opts(conn))

    assigns = [
      page_title: "Recent recordings",
      asciicasts: asciicasts
    ]

    render(conn, "recent_recordings.html", assigns)
  end

  def live_streams(conn, params) do
    streams =
      [:public, :live]
      |> Streaming.query(:recently_started)
      |> Streaming.paginate(params["page"], 14, pagination_opts(conn))

    assigns = [
      page_title: "Live streams",
      streams: streams
    ]

    render(conn, "live_streams.html", assigns)
  end

  def upcoming_streams(conn, params) do
    streams =
      [:public, :upcoming]
      |> Streaming.query(:soonest)
      |> Streaming.paginate(params["page"], 14, pagination_opts(conn))

    assigns = [
      page_title: "Upcoming streams",
      streams: streams
    ]

    render(conn, "upcoming_streams.html", assigns)
  end

  defp list_streams(query, limit) do
    items = Streaming.list(query, limit + 1)

    %{
      items: Enum.take(items, limit),
      has_more: length(items) > limit
    }
  end

  defp list_asciicasts(query, limit) do
    items = Recordings.list(query, limit + 1)

    %{
      items: Enum.take(items, limit),
      has_more: length(items) > limit
    }
  end
end
