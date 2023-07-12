defmodule AsciinemaWeb.LiveStreamStatusLive do
  alias Asciinema.Streaming
  alias Asciinema.Streaming.{LiveStreamServer, ViewerTracker}
  use AsciinemaWeb, :live_view

  @duration_update_interval 60_000

  @impl true
  def render(assigns) do
    ~H"""
    <div class="status-line">
      <%= case @status do %>
        <% :live -> %>
          <span class="status-line-item">
            <.live_icon />

            <%= if @duration do %>
              Streaming for <%= @duration %>
            <% else %>
              Stream just started
            <% end %>
          </span>

          <span class="status-line-item">
            <.eye_solid_icon /> <%= @viewer_count %> watching
          </span>
        <% :ended -> %>
          <span class="status-line-item">
            <.offline_icon /> Stream ended
          </span>
        <% :not_started -> %>
          <span class="status-line-item">
            <.offline_icon /> Stream hasn't started
          </span>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"stream_id" => stream_id}, socket) do
    if connected?(socket) do
      LiveStreamServer.subscribe(stream_id, :status)
      ViewerTracker.subscribe(stream_id)
      Process.send_after(self(), :update_duration, @duration_update_interval)
    end

    stream = Streaming.get_live_stream(stream_id)

    status =
      case {stream.online, stream.last_started_at} do
        {true, _} -> :live
        {false, nil} -> :not_started
        {false, _} -> :ended
      end

    socket =
      socket
      |> assign(
        status: status,
        last_started_at: stream.last_started_at || Timex.now(),
        viewer_count: stream.current_viewer_count
      )
      |> update_duration()

    {:ok, socket}
  end

  @impl true
  def handle_info({:live_stream, {:status, :online}}, socket) do
    if socket.assigns.status == :live do
      {:noreply, socket}
    else
      socket =
        socket
        |> assign(status: :live, last_started_at: Timex.now())
        |> update_duration()

      {:noreply, socket}
    end
  end

  def handle_info({:live_stream, {:status, :offline}}, socket) do
    if socket.assigns.status == :live do
      {:noreply, assign(socket, status: :ended)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%ViewerTracker.Update{viewer_count: c}, socket) do
    {:noreply, assign(socket, :viewer_count, c)}
  end

  def handle_info(:update_duration, socket) do
    Process.send_after(self(), :update_duration, @duration_update_interval)

    {:noreply, update_duration(socket)}
  end

  defp update_duration(socket) do
    assign(socket, :duration, format_duration(socket.assigns.last_started_at))
  end

  defp format_duration(time) do
    diff = Timex.diff(Timex.now(), time, :seconds)

    if diff < 60 do
      nil
    else
      diff
      |> Timex.Duration.from_seconds()
      |> Timex.format_duration(:humanized)
      |> String.split(", ")
      |> then(fn parts ->
        case length(parts) do
          l when l in [1, 2] -> Enum.take(parts, 1)
          _ -> Enum.take(parts, 2)
        end
      end)
      |> Enum.join(", ")
    end
  end
end
