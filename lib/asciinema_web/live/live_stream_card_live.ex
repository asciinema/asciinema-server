defmodule AsciinemaWeb.LiveStreamCardLive do
  use AsciinemaWeb, :live_view
  alias Asciinema.Streaming
  alias Asciinema.Streaming.StreamServer

  @impl true
  def render(assigns) do
    ~H"""
    <AsciinemaWeb.StreamHTML.live_stream_card
      stream={@stream}
      show_visibility_badge={@show_visibility_badge}
    />
    """
  end

  @impl true
  def mount(_params, %{"stream_id" => stream_id} = session, socket) do
    socket =
      assign(socket,
        stream: Streaming.get_stream(stream_id),
        show_visibility_badge: Map.get(session, "show_visibility_badge", false)
      )

    if connected?(socket) do
      StreamServer.subscribe(stream_id, :metadata)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(%StreamServer.Update{event: :metadata} = update, socket) do
    {:noreply, assign(socket, stream: update.data)}
  end
end
