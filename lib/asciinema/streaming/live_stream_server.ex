defmodule Asciinema.Streaming.LiveStreamServer do
  use GenServer, restart: :temporary
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

  def reset(stream_id, meta) do
    GenServer.call(via_tuple(stream_id), {:reset, meta})
  end

  def event(stream_id, event_type, payload) do
    GenServer.call(via_tuple(stream_id), {:event, {event_type, payload}})
  end

  def heartbeat(stream_id) do
    GenServer.call(via_tuple(stream_id), :heartbeat)
  end

  def subscribe(stream_id, types) when is_list(types) do
    Enum.each(types, &subscribe(stream_id, &1))
  end

  def subscribe(stream_id, type)
      when type in [:reset, :output, :input, :resize, :marker, :end, :metadata] do
    PubSub.subscribe(topic_name(stream_id, type))
  end

  def request_info(stream_id) do
    GenServer.cast(via_tuple(stream_id), {:info, self()})
  end

  def stop(stream_id, reason \\ :normal), do: GenServer.stop(via_tuple(stream_id), reason)

  # Callbacks

  @impl true
  def init(stream_id) do
    Logger.info("stream/#{stream_id}: init")

    Process.send_after(self(), :update_stream, 1_000)
    ViewerTracker.subscribe(stream_id)
    viewer_count = ViewerTracker.count(stream_id)
    stream = Streaming.get_live_stream(stream_id)

    state = %{
      stream: stream,
      stream_id: stream.id,
      producer: nil,
      vt: nil,
      vt_size: nil,
      theme: nil,
      last_stream_time: nil,
      last_event_time: nil,
      shutdown_timer: nil,
      viewer_count: viewer_count
    }

    state = reschedule_shutdown(state)

    {:ok, state}
  end

  @impl true
  def handle_call(:lead, {pid, _} = _from, state) do
    state = reschedule_shutdown(state)

    {:reply, :ok, %{state | producer: pid}}
  end

  def handle_call(_message, {pid1, _}, %{producer: pid2} = state) when pid1 != pid2 do
    Logger.info("stream/#{state.stream_id}: rejecting call from non-leader producer")

    {:reply, {:error, :leadership_lost}, state}
  end

  def handle_call({:reset, meta}, _from, state) do
    state = reset_stream(state, meta.term_size, meta.time, meta[:term_theme])

    if term_init = meta[:term_init] do
      Vt.feed(state.vt, term_init)
    end

    publish(state.stream_id, :reset, meta)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:output, event}}, _from, state) do
    {time, data} = event
    Vt.feed(state.vt, data)
    publish(state.stream_id, :output, event)
    state = update_time(state, time)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:input, event}}, _from, state) do
    {time, _data} = event
    publish(state.stream_id, :input, event)
    state = update_time(state, time)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:resize, event}}, _from, state) do
    {time, {cols, rows} = vt_size} = event
    Vt.resize(state.vt, cols, rows)
    publish(state.stream_id, :resize, event)

    state =
      state
      |> update_time(time)
      |> Map.put(:vt_size, vt_size)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:marker, event}}, _from, state) do
    {time, _data} = event
    publish(state.stream_id, :marker, event)
    state = update_time(state, time)

    {:reply, :ok, state}
  end

  def handle_call(:heartbeat, _from, state) do
    state = reschedule_shutdown(state)

    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:info, _from}, %{last_stream_time: nil} = state), do: {:noreply, state}

  def handle_cast({:info, pid}, state) do
    stream_time = current_stream_time(state.last_stream_time, state.last_event_time)

    send(pid, %Update{
      stream_id: state.stream_id,
      event: :info,
      data: %{
        term_size: state.vt_size,
        term_init: Vt.dump(state.vt),
        term_theme: state.theme,
        time: stream_time
      }
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

    stream =
      case state.vt_size do
        {cols, rows} ->
          stream =
            Streaming.update_live_stream(state.stream,
              current_viewer_count: state.viewer_count,
              cols: cols,
              rows: rows,
              snapshot: generate_snapshot(state.vt)
            )

          publish(state.stream_id, :metadata, stream)

          stream

        nil ->
          state.stream
      end

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

    time = current_stream_time(state.last_stream_time, state.last_event_time) || 0.0
    publish(state.stream_id, :end, %{time: time})
    Streaming.update_live_stream(state.stream, online: false)

    :ok
  end

  # Private

  defp via_tuple(stream_id),
    do: {:via, Horde.Registry, {Asciinema.Streaming.LiveStreamRegistry, stream_id}}

  defp update_time(state, time) do
    %{state | last_stream_time: time, last_event_time: Timex.now()}
  end

  defp publish(stream_id, event, data) do
    update = %Update{
      stream_id: stream_id,
      event: event,
      data: data
    }

    PubSub.broadcast(topic_name(stream_id, event), update)
  end

  defp topic_name(stream_id, type), do: "stream:#{stream_id}:#{type}"

  defp reset_stream(state, {cols, rows} = vt_size, time, theme) do
    {:ok, vt} = Vt.new(cols, rows, 100)

    stream =
      Streaming.update_live_stream(
        state.stream,
        Keyword.merge(
          [
            online: true,
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
        theme: theme
    }
    |> update_time(time)
  end

  defp reschedule_shutdown(state) do
    if state.shutdown_timer do
      Process.cancel_timer(state.shutdown_timer)
    end

    timer = Process.send_after(self(), :shutdown, 60 * 1000)

    %{state | shutdown_timer: timer}
  end

  defp current_stream_time(nil, nil), do: nil

  defp current_stream_time(last_stream_time, last_event_time) do
    last_stream_time + Timex.diff(Timex.now(), last_event_time, :microseconds)
  end

  defp theme_fields(nil), do: [theme_fg: nil, theme_bg: nil, theme_palette: nil]

  defp theme_fields(theme) do
    palette =
      theme.palette
      |> Enum.map(&Colors.hex/1)
      |> Enum.join(":")

    [
      theme_fg: Colors.hex(theme.fg),
      theme_bg: Colors.hex(theme.bg),
      theme_palette: palette
    ]
  end

  defp generate_snapshot(vt) do
    {:ok, {lines, cursor}} = Vt.dump_screen(vt)

    {lines, cursor}
  end
end
