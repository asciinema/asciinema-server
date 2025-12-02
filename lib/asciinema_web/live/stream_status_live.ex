defmodule AsciinemaWeb.StreamStatusLive do
  alias Asciinema.Streaming
  alias Asciinema.Streaming.{StreamServer, ViewerTracker}
  alias AsciinemaWeb.MediumHTML
  use AsciinemaWeb, :live_view

  defdelegate env_info(stream), to: MediumHTML

  @info_timeout 1_000
  @update_interval 10_000

  @impl true
  def render(assigns) do
    ~H"""
    <div class="status-line">
      <%= case status(@live, @last_started_at, @last_ended_at, @next_start_at, @now) do %>
        <% {:live, duration} -> %>
          <span class="status-line-item">
            <.live_icon />

            <%= if duration do %>
              Streaming for {duration}
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
        <% {:scheduled, remaining} -> %>
          <span class="status-line-item">
            <.offline_icon />

            <%= if remaining do %>
              Starts in {remaining}
            <% else %>
              Starts in a moment
            <% end %>
          </span>

          <span class="status-line-item">
            <.eye_solid_icon /> {@viewer_count} waiting
          </span>
        <% :not_started -> %>
          <span class="status-line-item">
            <.offline_icon /> Stream hasn't started
          </span>
        <% :ended -> %>
          <span class="status-line-item">
            <.offline_icon /> Stream ended
          </span>
      <% end %>
    </div>
    """
  end

  defp status(live, last_started_at, last_ended_at, next_start_at, now) do
    time_until_next_start = next_start_at && DateTime.diff(next_start_at, now)
    time_since_last_start = last_started_at && DateTime.diff(now, last_started_at)
    time_since_last_end = last_ended_at && DateTime.diff(now, last_ended_at)

    cond do
      live ->
        {:live, format_duration(time_since_last_start)}

      time_until_next_start &&
          (time_since_last_end == nil || time_since_last_end > 3600 ||
             time_until_next_start < 3600) ->
        {:scheduled, format_duration(time_until_next_start)}

      time_since_last_start ->
        :ended

      true ->
        :not_started
    end
  end

  @impl true
  def mount(_params, %{"stream_id" => stream_id}, socket) do
    if connected?(socket) do
      StreamServer.subscribe(stream_id, [:reset, :end, :metadata])
      StreamServer.request_info(stream_id)
      ViewerTracker.subscribe(stream_id)
      Process.send_after(self(), :info_timeout, @info_timeout)
      Process.send_after(self(), :update, @update_interval)
    end

    stream = Streaming.get_stream(stream_id)

    socket =
      assign(socket,
        live: stream.live,
        confirmed: false,
        last_started_at: stream.last_started_at,
        last_ended_at: if(!stream.live, do: stream.last_activity_at),
        next_start_at: stream.next_start_at,
        now: DateTime.utc_now(),
        viewer_count: stream.current_viewer_count,
        env_info_attrs: env_info_attrs(stream)
      )

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
    last_started_at = Timex.shift(Timex.now(), microseconds: -time)
    socket = assign(socket, live: true, last_started_at: last_started_at, confirmed: true)

    {:noreply, socket}
  end

  def handle_info(%StreamServer.Update{event: :end}, socket) do
    {:noreply, assign(socket, live: false, last_ended_at: DateTime.utc_now())}
  end

  def handle_info(%StreamServer.Update{event: :metadata, data: stream}, socket) do
    {:noreply, assign(socket, :env_info_attrs, env_info_attrs(stream))}
  end

  def handle_info(%ViewerTracker.Update{viewer_count: c}, socket) do
    {:noreply, assign(socket, :viewer_count, c)}
  end

  def handle_info(:update, socket) do
    Process.send_after(self(), :update, @update_interval)

    {:noreply, assign(socket, :now, DateTime.utc_now())}
  end

  defp env_info_attrs(stream),
    do: Map.take(stream, [:user_agent, :term_type, :term_version, :shell])

  defp format_duration(nil), do: nil

  defp format_duration(duration) do
    if duration < 60 do
      nil
    else
      duration
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
