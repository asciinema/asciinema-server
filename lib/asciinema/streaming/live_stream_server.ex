defmodule Asciinema.Streaming.LiveStreamServer do
  use GenServer, restart: :transient
  alias Asciinema.Streaming.ViewerTracker
  alias Asciinema.{PubSub, Streaming, Vt}
  require Logger

  # Client

  def start_link(stream_id) do
    GenServer.start_link(__MODULE__, stream_id, name: via_tuple(stream_id))
  end

  def lead(stream_id) do
    GenServer.call(via_tuple(stream_id), :lead)
  end

  def reset(stream_id, {_, _} = vt_size, vt_init \\ nil, stream_time \\ nil) do
    GenServer.call(via_tuple(stream_id), {:reset, vt_size, vt_init, stream_time})
  end

  def feed(stream_id, event) do
    GenServer.call(via_tuple(stream_id), {:feed, event})
  end

  def heartbeat(stream_id) do
    GenServer.call(via_tuple(stream_id), :heartbeat)
  end

  def join(stream_id) do
    subscribe(stream_id, :data)
    subscribe(stream_id, :status)
    GenServer.cast(via_tuple(stream_id), {:join, self()})
  end

  def subscribe(stream_id, type) when type in [:data, :status] do
    PubSub.subscribe(topic_name(stream_id, type))
  end

  def stop(stream_id, reason \\ :normal), do: GenServer.stop(via_tuple(stream_id), reason)

  # Callbacks

  @default_cols 80
  @default_rows 24

  @impl true
  def init(stream_id) do
    Logger.info("stream/#{stream_id}: init")

    Process.send_after(self(), :update_stream, 1_000)
    stream = Streaming.get_live_stream(stream_id)
    ViewerTracker.subscribe(stream_id)
    viewer_count = ViewerTracker.count(stream_id)

    state = %{
      stream: stream,
      stream_id: stream.id,
      producer: nil,
      vt: nil,
      vt_size: nil,
      last_stream_time: nil,
      last_feed_time: nil,
      shutdown_timer: nil,
      viewer_count: viewer_count
    }

    state =
      state
      |> reset_stream({@default_cols, @default_rows})
      |> reschedule_shutdown()

    {:ok, state}
  end

  @impl true
  def handle_call(:lead, {pid, _} = _from, state) do
    {:reply, :ok, %{state | producer: pid}}
  end

  def handle_call(
        {:reset, vt_size, vt_init, stream_time},
        {pid, _} = _from,
        %{producer: pid} = state
      ) do
    stream_time = stream_time || 0.0
    state = reset_stream(state, vt_size, stream_time)

    if vt_init do
      :ok = Vt.feed(state.vt, vt_init)
    end

    publish(state.stream_id, :data, {:live_stream, {:reset, {vt_size, vt_init, stream_time}}})
    publish(state.stream_id, :status, {:live_stream, {:status, :online}})

    {:reply, :ok, state}
  end

  def handle_call({:reset, _vt_size, _vt_init, _stream_time}, _from, state) do
    Logger.info("stream/#{state.stream_id}: rejecting reset from non-leader producer")

    {:reply, {:error, :not_a_leader}, state}
  end

  def handle_call({:feed, {time, data} = event}, {pid, _} = _from, %{producer: pid} = state) do
    :ok = Vt.feed(state.vt, data)
    publish(state.stream_id, :data, {:live_stream, {:feed, event}})

    {:reply, :ok, %{state | last_stream_time: time, last_feed_time: Timex.now()}}
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
  def handle_cast({:join, pid}, %{vt_size: vt_size} = state) do
    stream_time = current_stream_time(state.last_stream_time, state.last_feed_time)
    send(pid, {:live_stream, {:reset, {vt_size, Vt.dump(state.vt), stream_time}}})

    {:noreply, state}
  end

  @update_stream_interval 10_000

  @impl true
  def handle_info(%ViewerTracker.Update{viewer_count: c}, state) do
    {:noreply, %{state | viewer_count: c}}
  end

  def handle_info(:update_stream, state) do
    Process.send_after(self(), :update_stream, @update_stream_interval)
    stream = Streaming.update_live_stream(state.stream, current_viewer_count: state.viewer_count)

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

    publish(state.stream_id, :status, {:live_stream, {:status, :offline}})
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

  defp reset_stream(state, {cols, rows} = vt_size, stream_time \\ 0.0) do
    {:ok, vt} = Vt.new(cols, rows)

    stream =
      Streaming.update_live_stream(state.stream,
        online: true,
        last_started_at: Timex.shift(Timex.now(), seconds: -round(stream_time)),
        cols: cols,
        rows: rows
      )

    %{
      state
      | vt: vt,
        vt_size: vt_size,
        stream: stream,
        last_stream_time: stream_time,
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
end
