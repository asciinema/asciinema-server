defmodule AsciinemaWeb.LiveStreamHTML do
  use AsciinemaWeb, :html
  alias AsciinemaWeb.{PlayerView, RecordingView, UserView}

  embed_templates "live_stream/*"

  defdelegate author_username(stream), to: PlayerView
  defdelegate author_avatar_url(stream), to: PlayerView
  defdelegate author_profile_path(stream), to: PlayerView
  defdelegate theme_name(stream), to: PlayerView
  defdelegate default_theme_name(stream), to: PlayerView
  defdelegate terminal_font_family_options, to: PlayerView
  defdelegate theme_options, to: UserView

  def player_src(stream) do
    %{
      driver: "websocket",
      url: ws_consumer_url(stream),
      bufferTime: stream.buffer_time || 1.0
    }
  end

  def player_opts(stream, opts) do
    [
      cols: cols(stream),
      rows: rows(stream),
      autoplay: true,
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

  def title(stream), do: stream.title || "#{author_username(stream)}'s live stream"

  @http_to_ws %{"http" => "ws", "https" => "wss"}

  defp ws_producer_url(live_stream) do
    uri = AsciinemaWeb.Endpoint.struct_url()
    scheme = @http_to_ws[uri.scheme]
    path = "/ws/S/#{live_stream.producer_token}"

    to_string(%{uri | scheme: scheme, path: path})
  end

  defp ws_consumer_url(live_stream) do
    param = Phoenix.Param.to_param(live_stream)
    String.replace(AsciinemaWeb.Endpoint.url() <> "/ws/s/#{param}", ~r/^http/, "ws")
  end

  defp cols(stream), do: stream.cols || 80

  defp rows(stream), do: stream.rows || 24
end
