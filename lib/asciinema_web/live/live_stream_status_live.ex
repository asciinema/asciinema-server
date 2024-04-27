defmodule AsciinemaWeb.LiveStreamStatusLive do
  alias Asciinema.Streaming
  alias Asciinema.Streaming.{LiveStreamServer, ViewerTracker}
  use AsciinemaWeb, :live_view

  @info_timeout 1_000
  @duration_update_interval 60_000

  @impl true
  def render(assigns) do
    ~H"""
    <div class="status-line">
      <%= case {@online, @started_at} do %>
        <% {true, _} -> %>
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
        <% {false, nil} -> %>
          <span class="status-line-item">
            <.offline_icon /> Stream hasn't started
          </span>
        <% {false, _} -> %>
          <span class="status-line-item">
            <.offline_icon /> Stream ended
          </span>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"stream_id" => stream_id}, socket) do
    if connected?(socket) do
      LiveStreamServer.subscribe(stream_id, :reset)
      LiveStreamServer.subscribe(stream_id, :offline)
      LiveStreamServer.request_info(stream_id)
      ViewerTracker.subscribe(stream_id)
      Process.send_after(self(), :info_timeout, @info_timeout)
    end

    stream = Streaming.get_live_stream(stream_id)

    socket =
      socket
      |> assign(
        online: stream.online,
        confirmed: false,
        started_at: stream.last_started_at,
        duration: nil,
        viewer_count: stream.current_viewer_count
      )
      |> update_duration()

    {:ok, socket}
  end

  @impl true
  def handle_info(:info_timeout, socket) do
    if socket.assigns.confirmed do
      {:noreply, socket}
    else
      {:noreply, assign(socket, :online, false)}
    end
  end

  def handle_info(%LiveStreamServer.Update{event: e} = update, socket)
      when e in [:info, :reset] do
    {_, _, time, _} = update.data
    started_at = Timex.shift(Timex.now(), milliseconds: -round(time * 1000.0))

    socket =
      socket
      |> assign(online: true, started_at: started_at, confirmed: true)
      |> update_duration()

    {:noreply, socket}
  end

  def handle_info(%LiveStreamServer.Update{event: :offline}, socket) do
    {:noreply, assign(socket, online: false)}
  end

  def handle_info(%ViewerTracker.Update{viewer_count: c}, socket) do
    {:noreply, assign(socket, :viewer_count, c)}
  end

  def handle_info(:update_duration, socket) do
    {:noreply, update_duration(socket)}
  end

  defp update_duration(socket) do
    socket = assign(socket, :duration, format_duration(socket.assigns.started_at))

    if connected?(socket) do
      if timer = socket.assigns[:update_timer] do
        Process.cancel_timer(timer)
      end

      timer = Process.send_after(self(), :update_duration, @duration_update_interval)

      assign(socket, :update_timer, timer)
    else
      socket
    end
  end

  defp format_duration(nil), do: nil

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
