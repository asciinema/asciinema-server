defmodule Asciinema.LiveStream do
  use GenServer, restart: :transient
  alias Asciinema.Vt
  require Logger

  # Client

  def start_link(stream_id) do
    GenServer.start_link(__MODULE__, stream_id, name: via_tuple(stream_id))
  end

  def lead(stream_id) do
    GenServer.call(via_tuple(stream_id), :lead)
  end

  def reset(stream_id, {_, _} = vt_size) do
    GenServer.call(via_tuple(stream_id), {:reset, vt_size})
  end

  def feed(stream_id, event) do
    GenServer.call(via_tuple(stream_id), {:feed, event})
  end

  def heartbeat(stream_id) do
    GenServer.call(via_tuple(stream_id), :heartbeat)
  end

  def join(stream_id) do
    subscribe({:live_stream, stream_id})
    GenServer.cast(via_tuple(stream_id), {:join, self()})
  end

  def stop(stream_id), do: GenServer.stop(via_tuple(stream_id))

  # Callbacks

  @impl true
  def init(stream_id) do
    Logger.info("stream/#{stream_id}: init")

    # TODO load vt size and last known state from db
    vt_size = {80, 24}
    last_stream_time = 0.0
    last_feed_time = Timex.now()
    last_vt_state = ""

    {cols, rows} = vt_size
    {:ok, vt} = Vt.new(cols, rows)
    :ok = Vt.feed(vt, last_vt_state)

    stream_time = current_stream_time(last_stream_time, last_feed_time)

    publish(
      {:live_stream, stream_id},
      {:live_stream, {:init, {vt_size, last_vt_state, stream_time}}}
    )

    state = %{
      stream_id: stream_id,
      producer: nil,
      vt: vt,
      vt_size: vt_size,
      last_stream_time: last_stream_time,
      last_feed_time: last_feed_time,
      shutdown_timer: nil
    }

    state = reschedule_shutdown(state)

    {:ok, state}
  end

  @impl true
  def handle_call(:lead, {pid, _} = _from, state) do
    {:reply, :ok, %{state | producer: pid}}
  end

  def handle_call({:reset, {cols, rows} = vt_size}, {pid, _} = _from, %{producer: pid} = state) do
    {:ok, vt} = Vt.new(cols, rows)
    publish({:live_stream, state.stream_id}, {:live_stream, {:reset, vt_size}})

    {:reply, :ok, %{state | vt: vt, vt_size: vt_size}}
  end

  def handle_call({:reset, _vt_size}, _from, state) do
    Logger.info("stream/#{state.stream_id}: rejecting reset from non-leader producer")

    {:reply, {:error, :not_a_leader}, state}
  end

  def handle_call({:feed, {time, data} = event}, {pid, _} = _from, %{producer: pid} = state) do
    :ok = Vt.feed(state.vt, data)
    publish({:live_stream, state.stream_id}, {:live_stream, {:feed, event}})

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
  def handle_cast({:join, pid}, state) do
    stream_time = current_stream_time(state.last_stream_time, state.last_feed_time)
    send(pid, {:live_stream, {:init, {state.vt_size, Vt.dump(state.vt), stream_time}}})

    {:noreply, state}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:shutdown, state) do
    Logger.info("stream/#{state.stream_id}: shutting down due to missing heartbeats")
    publish({:live_stream, state.stream_id}, {:live_stream, :end})

    {:stop, :normal, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("stream/#{state.stream_id}: terminating | reason: #{reason}, state: #{inspect(state)}")

    :ok
  end

  # Private

  defp via_tuple(stream_id), do: {:via, Registry, {Asciinema.LiveStreamRegistry, stream_id}}

  defp subscribe(topic) do
    {:ok, _} = Registry.register(Asciinema.PubSubRegistry, topic, [])
  end

  defp publish(topic, payload) do
    Registry.dispatch(Asciinema.PubSubRegistry, topic, fn entries ->
      for {pid, _} <- entries, do: send(pid, payload)
    end)
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
