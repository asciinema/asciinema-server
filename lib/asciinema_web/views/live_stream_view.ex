defmodule AsciinemaWeb.LiveStreamView do
  use AsciinemaWeb, :view
  alias AsciinemaWeb.PlayerView

  defdelegate author_username(stream), to: PlayerView
  defdelegate author_avatar_url(stream), to: PlayerView
  defdelegate author_profile_path(stream), to: PlayerView
  defdelegate theme_name(stream), to: PlayerView

  def player_src(stream) do
    %{
      driver: "websocket",
      url: ws_consumer_url(stream),
      bufferTime: 1.0
    }
  end

  def player_opts(stream, opts) do
    [
      cols: cols(stream),
      rows: rows(stream),
      theme: theme_name(stream),
      terminalLineHeight: stream.terminal_line_height,
      customTerminalFontFamily: stream.terminal_font_family
    ]
    |> Keyword.merge(opts)
    |> Enum.into(%{})
  end

  def cinema_height(stream) do
    PlayerView.cinema_height(cols(stream), rows(stream))
  end

  def title(stream), do: stream.description || "Live stream"

  defp ws_consumer_url(live_stream) do
    param = Phoenix.Param.to_param(live_stream)
    String.replace(AsciinemaWeb.Endpoint.url() <> "/ws/s/#{param}", ~r/^http/, "ws")
  end

  defp cols(stream), do: stream.cols || 80

  defp rows(stream), do: stream.rows || 24
end
