defmodule AsciinemaWeb.HomeController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Recordings, Streaming}

  def show(conn, _params) do
    asciicast =
      if id = Application.get_env(:asciinema, :home_asciicast_id) do
        Recordings.get_asciicast(id, load_snapshot: true)
      else
        :public
        |> Recordings.query()
        |> Recordings.list(1)
        |> List.first()
      end

    live_streams = fetch_live_streams()
    featured_asciicasts = fetch_featured_asciicasts()
    popular_asciicasts = fetch_popular_asciicasts()

    render(
      conn,
      :show,
      asciicast: asciicast,
      live_streams: live_streams,
      featured_asciicasts: featured_asciicasts,
      popular_asciicasts: popular_asciicasts
    )
  end

  defp fetch_live_streams do
    [:public, :live]
    |> Streaming.query(:recently_started)
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
    seed = Date.utc_today()

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
