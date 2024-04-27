defmodule AsciinemaWeb.LiveStreamCardLive do
  use AsciinemaWeb, :live_view
  alias Asciinema.Streaming
  alias Asciinema.Streaming.LiveStreamServer

  @impl true
  def render(assigns) do
    ~H"""
    <AsciinemaWeb.LiveStreamHTML.card stream={@stream} />
    """
  end

  @impl true
  def mount(_params, %{"stream_id" => stream_id}, socket) do
    socket = assign(socket, :stream, Streaming.get_live_stream(stream_id))

    if connected?(socket) do
      LiveStreamServer.subscribe(stream_id, :metadata)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(%LiveStreamServer.Update{event: :metadata} = update, socket) do
    {:noreply, assign(socket, stream: update.data)}
  end
end
