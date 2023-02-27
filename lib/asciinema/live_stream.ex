defmodule Asciinema.LiveStream do
  use GenServer, restart: :transient
  alias Asciinema.Vt
  require Logger

  # Client

  def start_link(stream_id) do
    GenServer.start_link(__MODULE__, stream_id, name: via_tuple(stream_id))
  end

  def reset(stream_id, {_, _} = vt_size) do
    :ok = GenServer.call(via_tuple(stream_id), {:reset, vt_size})
  end

  def feed(stream_id, event) do
    :ok = GenServer.call(via_tuple(stream_id), {:feed, event})
  end

  def join(stream_id) do
    Logger.debug("client: join")

    ref1 = make_ref()
    ref2 = make_ref()

    Logger.debug("client: casting")

    :ok = GenServer.cast(via_tuple(stream_id), {:join, {self(), ref1, ref2}})

    Logger.debug("client: waiting for stream state")

    receive do
      {^ref1, pid, {_vt_size, _vt_state, _stream_time} = stream_state} ->
        Logger.debug("client: got stream state, subscribing")
        subscribe(stream_id)
        Logger.debug("client: releasing server")
        send(pid, ref2)

        {:ok, stream_state}
    after
      5000 ->
        Logger.debug("client: live stream server not responding")

        :error
    end
  end

  def stop(stream_id), do: GenServer.stop(via_tuple(stream_id))

  def crash(stream_id), do: GenServer.cast(via_tuple(stream_id), :raise)

  # Callbacks

  @impl true
  def init(stream_id) do
    Logger.info("initializing live stream #{stream_id}...")

    # TODO load cols/rows and last known dump from db

    vt_size = {80, 24}
    last_vt_state = ""

    {cols, rows} = vt_size
    {:ok, vt} = Vt.new(cols, rows)
    :ok = Vt.feed(vt, last_vt_state)

    state = %{
      stream_id: stream_id,
      vt: vt,
      vt_size: vt_size,
      last_stream_time: 0.0,
      last_feed_time: Timex.now()
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:reset, {cols, rows} = vt_size}, _from, state) do
    {:ok, vt} = Vt.new(cols, rows)
    publish(state.stream_id, {:reset, vt_size})

    {:reply, :ok, %{state | vt: vt, vt_size: vt_size}}
  end

  def handle_call({:feed, {time, data} = event}, _from, state) do
    :ok = Vt.feed(state.vt, data)
    publish(state.stream_id, {:feed, event})

    {:reply, :ok, %{state | last_stream_time: time, last_feed_time: Timex.now()}}
  end

  @impl true
  def handle_cast({:join, {pid, ref1, ref2}}, state) do
    Logger.debug("server: sending stream state")

    stream_time =
      state.last_stream_time +
        Timex.diff(Timex.now(), state.last_feed_time, :milliseconds) / 1000.0

    send(pid, {ref1, self(), {state.vt_size, Vt.dump(state.vt), stream_time}})

    Logger.debug("server: waiting for client subscribe")

    receive do
      ^ref2 ->
        Logger.debug("server: client successfully subscribed")
        :ok
    after
      5000 ->
        Logger.warn("server: timed out waiting for client subscribe")
        :ok
    end

    {:noreply, state}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  # Private

  defp via_tuple(stream_id), do: {:via, Registry, {Asciinema.LiveStreamRegistry, stream_id}}

  defp subscribe(stream_id) do
    {:ok, _} = Registry.register(Asciinema.PubSubRegistry, {:live_stream, stream_id}, [])
  end

  defp publish(stream_id, data) do
    Registry.dispatch(Asciinema.PubSubRegistry, {:live_stream, stream_id}, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:live_stream, data})
    end)
  end
end
