defmodule AsciinemaWeb.UpcomingStreamCardLive do
  use AsciinemaWeb, :live_view
  alias Asciinema.Streaming
  alias Asciinema.Streaming.StreamServer
  alias AsciinemaWeb.StreamHTML

  @tick_interval 1_000

  @impl true
  def render(assigns) do
    ~H"""
    <StreamHTML.upcoming_stream_card stream={@stream} status={@status} />
    """
  end

  @impl true
  def mount(_params, %{"stream_id" => stream_id}, socket) do
    stream = Streaming.get_stream(stream_id)
    socket = assign(socket, stream: stream, status: {:waiting, remaining(stream)})

    if connected?(socket) do
      StreamServer.subscribe(stream_id, [:reset, :end])
      StreamServer.request_info(stream_id)
      Process.send_after(self(), :tick, @tick_interval)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    case socket.assigns.status do
      {:waiting, remaining} when not is_nil(remaining) ->
        Process.send_after(self(), :tick, @tick_interval)

        {:noreply, assign(socket, status: {:waiting, remaining(socket.assigns.stream)})}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(%StreamServer.Update{event: e}, socket) when e in [:info, :reset] do
    {:noreply, assign(socket, status: :live)}
  end

  def handle_info(%StreamServer.Update{event: :end}, socket) do
    {:noreply, assign(socket, status: :ended)}
  end

  defp remaining(stream) do
    duration = DateTime.diff(stream.next_start_at, DateTime.utc_now())

    format_duration(duration)
  end

  @day_in_sec 60 * 60 * 24
  @hour_in_sec 60 * 60
  @min_in_sec 60

  defp format_duration(duration) do
    if duration < 1 do
      nil
    else
      days = div(duration, @day_in_sec)
      duration = rem(duration, @day_in_sec)
      hours = div(duration, @hour_in_sec)
      duration = rem(duration, @hour_in_sec)
      minutes = div(duration, @min_in_sec)
      seconds = rem(duration, @min_in_sec)

      "#{days}d #{hours}h #{minutes}m #{seconds}s"
    end
  end
end
