defmodule Asciinema.Streaming.LiveStreamServer do
  use GenServer, restart: :transient
  alias Asciinema.Streaming.ViewerTracker
  alias Asciinema.{Colors, PubSub, Streaming, Vt}
  require Logger

  defmodule Update do
    defstruct [:stream_id, :event, :data]
  end

  # Client

  def start_link(stream_id) do
    GenServer.start_link(__MODULE__, stream_id, name: via_tuple(stream_id))
  end

  def lead(stream_id) do
    GenServer.call(via_tuple(stream_id), :lead)
  end

  def reset(stream_id, {_, _} = vt_size, vt_init \\ nil, stream_time \\ nil, theme \\ nil) do
    GenServer.call(via_tuple(stream_id), {:reset, vt_size, vt_init, stream_time, theme})
  end

  def feed(stream_id, event) do
    GenServer.call(via_tuple(stream_id), {:feed, event})
  end

  def heartbeat(stream_id) do
    GenServer.call(via_tuple(stream_id), :heartbeat)
  end

  def subscribe(stream_id, type) when type in [:stream, :status] do
    PubSub.subscribe(topic_name(stream_id, type))
  end

  def request_info(stream_id) do
    GenServer.cast(via_tuple(stream_id), {:info, self()})
  end

  def stop(stream_id, reason \\ :normal), do: GenServer.stop(via_tuple(stream_id), reason)

  # Callbacks

  @default_cols 80
  @default_rows 24

  @impl true
  def init(stream_id) do
    Logger.info("stream/#{stream_id}: init")

    Process.send_after(self(), :update_stream, 1_000)
    ViewerTracker.subscribe(stream_id)
    viewer_count = ViewerTracker.count(stream_id)

    stream =
      stream_id
      |> Streaming.get_live_stream()
      |> Streaming.update_live_stream(online: true)

    state = %{
      stream: stream,
      stream_id: stream.id,
      producer: nil,
      vt: nil,
      vt_size: nil,
      theme: nil,
      last_stream_time: nil,
      last_feed_time: nil,
      shutdown_timer: nil,
      viewer_count: viewer_count
    }

    state =
      state
      |> reset_stream({@default_cols, @default_rows})
      |> reschedule_shutdown()

    publish(stream_id, :status, %Update{
      stream_id: stream_id,
      event: :status,
      data: :online
    })

    {:ok, state}
  end

  @impl true
  def handle_call(:lead, {pid, _} = _from, state) do
    {:reply, :ok, %{state | producer: pid}}
  end

  def handle_call(
        {:reset, vt_size, vt_init, stream_time, theme},
        {pid, _} = _from,
        %{producer: pid} = state
      ) do
    stream_time = stream_time || 0.0
    state = reset_stream(state, vt_size, stream_time, theme)

    if vt_init do
      Vt.feed(state.vt, vt_init)
    end

    publish(state.stream_id, :stream, %Update{
      stream_id: state.stream_id,
      event: :reset,
      data: {vt_size, vt_init, stream_time, theme}
    })

    {:reply, :ok, state}
  end

  def handle_call({:reset, _vt_size, _vt_init, _stream_time, _theme}, _from, state) do
    Logger.info("stream/#{state.stream_id}: rejecting reset from non-leader producer")

    {:reply, {:error, :not_a_leader}, state}
  end

  def handle_call({:feed, {time, data} = event}, {pid, _} = _from, %{producer: pid} = state) do
    new_size = Vt.feed(state.vt, data)

    publish(state.stream_id, :stream, %Update{
      stream_id: state.stream_id,
      event: :feed,
      data: event
    })

    state = %{
      state
      | last_stream_time: time,
        last_feed_time: Timex.now(),
        vt_size: new_size || state.vt_size
    }

    {:reply, :ok, state}
  end

  def handle_call({:feed, _event}, _from, state) do
    Logger.info("stream/#{state.stream_id}: rejecting feed from non-leader producer")

    {:reply, {:error, :not_a_leader}, state}
  end

  def handle_call(:heartbeat, {pid, _} = _from, %{producer: pid} = state) do
    state = reschedule_shutdown(state)

    {:reply, :ok, state}
  end

  def handle_call(:heartbeat, _from, state) do
    Logger.info("stream/#{state.stream_id}: rejecting heartbeat from non-leader producer")

    {:reply, {:error, :not_a_leader}, state}
  end

  @impl true
  def handle_cast({:info, pid}, state) do
    stream_time = current_stream_time(state.last_stream_time, state.last_feed_time)

    send(pid, %Update{
      stream_id: state.stream_id,
      event: :info,
      data: {state.vt_size, Vt.dump(state.vt), stream_time, state.theme}
    })

    {:noreply, state}
  end

  @update_stream_interval 10_000

  @impl true
  def handle_info(%ViewerTracker.Update{viewer_count: c}, state) do
    {:noreply, %{state | viewer_count: c}}
  end

  def handle_info(:update_stream, state) do
    Process.send_after(self(), :update_stream, @update_stream_interval)
    {cols, rows} = state.vt_size

    stream =
      Streaming.update_live_stream(state.stream,
        current_viewer_count: state.viewer_count,
        cols: cols,
        rows: rows
      )

    {:noreply, %{state | stream: stream}}
  end

  def handle_info(:shutdown, state) do
    Logger.info("stream/#{state.stream_id}: shutting down due to missing heartbeats")

    {:stop, :normal, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("stream/#{state.stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("stream/#{state.stream_id}: state: #{inspect(state)}")

    publish(state.stream_id, :status, %Update{
      stream_id: state.stream_id,
      event: :status,
      data: :offline
    })

    Streaming.update_live_stream(state.stream, online: false)

    :ok
  end

  # Private

  defp via_tuple(stream_id),
    do: {:via, Horde.Registry, {Asciinema.Streaming.LiveStreamRegistry, stream_id}}

  defp publish(stream_id, type, payload) do
    PubSub.broadcast(topic_name(stream_id, type), payload)
  end

  defp topic_name(stream_id, type), do: "stream:#{stream_id}:#{type}"

  defp reset_stream(state, {cols, rows} = vt_size, time \\ 0.0, theme \\ nil) do
    {:ok, vt} = Vt.new(cols, rows, true, 100)

    stream =
      Streaming.update_live_stream(
        state.stream,
        Keyword.merge(
          [
            last_started_at: Timex.shift(Timex.now(), milliseconds: -round(time * 1000.0)),
            cols: cols,
            rows: rows
          ],
          theme_fields(theme)
        )
      )

    %{
      state
      | vt: vt,
        vt_size: vt_size,
        stream: stream,
        theme: theme,
        last_stream_time: time,
        last_feed_time: Timex.now()
    }
  end

  defp reschedule_shutdown(state) do
    if state.shutdown_timer do
      Process.cancel_timer(state.shutdown_timer)
    end

    timer = Process.send_after(self(), :shutdown, 60 * 1000)

    %{state | shutdown_timer: timer}
  end

  defp current_stream_time(last_stream_time, last_feed_time) do
    last_stream_time + Timex.diff(Timex.now(), last_feed_time, :milliseconds) / 1000.0
  end

  defp theme_fields(nil), do: []

  defp theme_fields(theme) when byte_size(theme) == 18 * 3 do
    colors = for <<r::8, g::8, b::8 <- theme>>, do: Colors.hex(r, g, b)

    [
      theme_fg: Enum.at(colors, 0),
      theme_bg: Enum.at(colors, 1),
      theme_palette: Enum.join(Enum.slice(colors, 2..-1), ":")
    ]
  end
end
