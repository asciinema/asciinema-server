defmodule AsciinemaWeb.StreamStatusLive do
  alias Asciinema.Streaming
  alias Asciinema.Streaming.{StreamServer, ViewerTracker}
  alias AsciinemaWeb.MediumHTML
  use AsciinemaWeb, :live_view

  defdelegate env_info(stream), to: MediumHTML

  @info_timeout 1_000
  @duration_update_interval 60_000

  @impl true
  def render(assigns) do
    ~H"""
    <div class="status-line">
      <%= case {@live, @started_at} do %>
        <% {true, _} -> %>
          <span class="status-line-item">
            <.live_icon />

            <%= if @duration do %>
              Streaming for {@duration}
            <% else %>
              Stream just started
            <% end %>
          </span>

          <span class="status-line-item">
            <.terminal_solid_icon /> <.env_info attrs={@env_info_attrs} />
          </span>

          <span class="status-line-item">
            <.eye_solid_icon /> {@viewer_count} watching
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
      StreamServer.subscribe(stream_id, [:reset, :end, :metadata])
      StreamServer.request_info(stream_id)
      ViewerTracker.subscribe(stream_id)
      Process.send_after(self(), :info_timeout, @info_timeout)
    end

    stream = Streaming.get_stream(stream_id)

    socket =
      socket
      |> assign(
        live: stream.live,
        confirmed: false,
        started_at: stream.last_started_at,
        duration: nil,
        viewer_count: stream.current_viewer_count,
        env_info_attrs: env_info_attrs(stream)
      )
      |> update_duration()

    {:ok, socket}
  end

  @impl true
  def handle_info(:info_timeout, socket) do
    if socket.assigns.confirmed do
      {:noreply, socket}
    else
      {:noreply, assign(socket, :live, false)}
    end
  end

  def handle_info(%StreamServer.Update{event: e} = update, socket)
      when e in [:info, :reset] do
    %{time: time} = update.data
    started_at = Timex.shift(Timex.now(), microseconds: -time)

    socket =
      socket
      |> assign(live: true, started_at: started_at, confirmed: true)
      |> update_duration()

    {:noreply, socket}
  end

  def handle_info(%StreamServer.Update{event: :end}, socket) do
    {:noreply, assign(socket, live: false)}
  end

  def handle_info(%StreamServer.Update{event: :metadata, data: stream}, socket) do
    {:noreply, assign(socket, :env_info_attrs, env_info_attrs(stream))}
  end

  def handle_info(%ViewerTracker.Update{viewer_count: c}, socket) do
    {:noreply, assign(socket, :viewer_count, c)}
  end

  def handle_info(:update_duration, socket) do
    {:noreply, update_duration(socket)}
  end

  defp env_info_attrs(stream),
    do: Map.take(stream, [:user_agent, :term_type, :term_version, :shell])

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
