defmodule AsciinemaWeb.LiveStreamHTML do
  use AsciinemaWeb, :html
  alias Asciinema.{Accounts, Fonts, Media, Themes}
  alias AsciinemaWeb.{MediaView, RecordingHTML}

  embed_templates "live_stream/*"

  defdelegate author_username(stream), to: MediaView
  defdelegate author_avatar_url(stream), to: MediaView
  defdelegate author_profile_path(stream), to: MediaView
  defdelegate theme_options, to: MediaView
  defdelegate font_family_options, to: MediaView

  def player_src(stream) do
    %{
      driver: "websocket",
      url: ws_consumer_url(stream),
      bufferTime: stream.buffer_time && stream.buffer_time * 1000.0
    }
  end

  def player_opts(stream, opts) do
    [
      cols: cols(stream),
      rows: rows(stream),
      autoplay: true,
      theme: theme_name(stream),
      terminalLineHeight: stream.terminal_line_height,
      customTerminalFontFamily: Media.font_family(stream)
    ]
    |> Keyword.merge(opts)
    |> Enum.into(%{})
  end

  defp theme_name(stream) do
    if stream.theme_prefer_original do
      "auto/#{Media.theme_name(stream)}"
    else
      Media.theme_name(stream)
    end
  end

  def cinema_height(stream) do
    MediaView.cinema_height(cols(stream), rows(stream))
  end

  def title(stream), do: stream.title || "#{author_username(stream)}'s live stream"

  def default_theme_display_name(stream) do
    "Account default (#{Themes.display_name(Accounts.default_theme_name(stream.user) || "asciinema")})"
  end

  def default_font_display_name(user) do
    Fonts.display_name(Accounts.default_font_family(user) || "default")
  end

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
