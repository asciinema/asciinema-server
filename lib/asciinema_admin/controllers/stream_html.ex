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
end
