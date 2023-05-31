defmodule AsciinemaWeb.LiveStreamView do
  use AsciinemaWeb, :view
  import AsciinemaWeb.RecordingView, only: [cinema_height: 1]
  alias AsciinemaWeb.UserView

  def player(src, opts \\ [])

  def player(src, opts) when is_binary(src) do
    {container_id, opts} = Keyword.pop!(opts, :container_id)

    src = %{
      driver: "websocket",
      url: src,
      bufferTime: 1.0
    }

    props =
      [src: src]
      |> Keyword.merge(opts)
      |> Enum.into(%{})

    props_json =
      props
      |> Jason.encode!()
      |> String.replace(~r/</, "\\u003c")

    content_tag(:script) do
      ~E"""
        window.players = window.players || new Map();
        window.players.set('<%= container_id %>', <%= {:safe, props_json} %>);
      """
    end
  end

  def player(live_stream, opts) do
    opts =
      Keyword.merge(
        [
          cols: cols(live_stream),
          rows: rows(live_stream),
          theme: theme_name(live_stream)
          # poster: poster(live_stream.snapshot),
        ],
        opts
      )

    player(ws_consumer_url(live_stream), opts)
  end

  defp cols(live_stream), do: live_stream.cols_override || live_stream.cols

  defp rows(live_stream), do: live_stream.rows_override || live_stream.rows

  def theme_name(live_stream) do
    live_stream.theme_name || default_theme_name(live_stream)
  end

  def default_theme_name(live_stream) do
    UserView.theme_name(live_stream.user) || "asciinema"
  end

  # TODO use Routes
  defp ws_consumer_url(live_stream) do
    String.replace(AsciinemaWeb.Endpoint.url() <> "/ws/s/#{live_stream.id}", ~r/^http/, "ws")
  end

  # TODO make it live - with cinema height automatically recalculated and updated
end
