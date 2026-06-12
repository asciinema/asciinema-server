defmodule AsciinemaAdmin.StreamHTML do
  use AsciinemaAdmin, :html

  embed_templates "stream_html/*"

  @doc """
  WebSocket URL for the stream's player. Points at the public endpoint —
  private streams aren't authorized from an anonymous WS handshake, so the
  player will fail to connect for `:private` visibility. Inline preview of
  private streams isn't supported by this embed.
  """
  def player_src(stream) do
    uri = AsciinemaWeb.Endpoint.struct_url()
    scheme = if uri.scheme == "https", do: "wss", else: "ws"
    path = "/ws/s/#{stream.public_token}"
    to_string(%{uri | scheme: scheme, path: path})
  end

  @doc "80×24 covers streams with no producer yet; autoplay spares a click per preview."
  def player_opts(stream) do
    %{
      cols: stream.term_cols || 80,
      rows: stream.term_rows || 24,
      theme: Asciinema.Media.player_theme_name(stream),
      customTerminalFontFamily: Asciinema.Media.font_family(stream),
      autoplay: true
    }
  end
end
