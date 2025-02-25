defmodule Asciinema.Streaming.StreamServer do
  use GenServer, restart: :temporary
  use Asciinema.Config
  alias Asciinema.Recordings
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

  def reset(stream_id, args, user_agent, query) do
    payload = %{args: args, user_agent: user_agent, query: query}
    GenServer.call(via_tuple(stream_id), {:reset, payload})
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

    Process.send_after(self(), :update_schema, 1_000)
    ViewerTracker.subscribe(stream_id)
    viewer_count = ViewerTracker.count(stream_id)
    stream = Streaming.get_stream(stream_id)

    state = %{
      stream: stream,
      stream_id: stream.id,
      producer: nil,
      vt: nil,
      vt_size: nil,
      theme: nil,
      last_event_id: 0,
      base_stream_time: nil,
      last_stream_time: nil,
      last_event_time: nil,
      user_agent: nil,
      path: nil,
      file: nil,
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

  def handle_call({:reset, payload}, _from, state) do
    %{args: args, user_agent: user_agent, query: query} = payload
    %{time: time, last_id: last_id, term_size: {cols, rows}} = args
    theme = args[:term_theme]
    last_started_at = Timex.shift(Timex.now(), microseconds: -round(time))

    schema_changes =
      Keyword.merge(
        [online: true, last_started_at: last_started_at, cols: cols, rows: rows],
        schema_theme_fields(theme)
      )

    state =
      %{state | theme: theme, user_agent: user_agent}
      |> reset_vt(cols, rows)
      |> update_base_stream_time(last_id, time)
      |> update_last_stream_time(time)
      |> update_schema(schema_changes)
      |> restart_recording(last_id, cols, rows, args[:term_init], theme, query)
      |> save_event_id(last_id)

    if term_init = args[:term_init] do
      Vt.feed(state.vt, term_init)
    end

    publish(state.stream_id, :reset, args)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:output, data}}, _from, state) do
    %{id: id, time: time, text: text} = data
    Vt.feed(state.vt, text)
    publish(state.stream_id, :output, data)
    write_asciicast_v2_event(state, time, "o", text)

    state =
      state
      |> update_last_stream_time(time)
      |> save_event_id(id)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:input, data}}, _from, state) do
    %{id: id, time: time, text: text} = data
    publish(state.stream_id, :input, data)
    write_asciicast_v2_event(state, time, "i", text)

    state =
      state
      |> update_last_stream_time(time)
      |> save_event_id(id)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:resize, data}}, _from, state) do
    %{id: id, time: time, term_size: {cols, rows} = vt_size} = data
    Vt.resize(state.vt, cols, rows)
    publish(state.stream_id, :resize, data)
    write_asciicast_v2_event(state, time, "r", "#{cols}x#{rows}")

    state =
      state
      |> update_last_stream_time(time)
      |> Map.put(:vt_size, vt_size)
      |> save_event_id(id)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:marker, data}}, _from, state) do
    %{id: id, time: time, label: label} = data
    publish(state.stream_id, :marker, data)
    write_asciicast_v2_event(state, time, "m", label)

    state =
      state
      |> update_last_stream_time(time)
      |> save_event_id(id)

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
        last_id: state.last_event_id,
        term_size: state.vt_size,
        term_init: Vt.dump(state.vt),
        term_theme: state.theme,
        time: stream_time
      }
    })

    {:noreply, state}
  end

  @update_schema_interval 5_000

  @impl true
  def handle_info(%ViewerTracker.Update{viewer_count: c}, state) do
    {:noreply, %{state | viewer_count: c}}
  end

  def handle_info(:update_schema, %{vt_size: nil} = state) do
    Process.send_after(self(), :update_schema, @update_schema_interval)

    {:noreply, state}
  end

  def handle_info(:update_schema, %{vt_size: {cols, rows}} = state) do
    Process.send_after(self(), :update_schema, @update_schema_interval)

    state =
      update_schema(state,
        current_viewer_count: state.viewer_count,
        cols: cols,
        rows: rows,
        snapshot: generate_snapshot(state.vt)
      )

    publish(state.stream_id, :metadata, state.stream)

    {:noreply, state}
  end

  def handle_info(:shutdown, state) do
    Logger.info("stream/#{state.stream_id}: shutting down due to missing heartbeats")

    {:stop, :normal, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("stream/#{state.stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("stream/#{state.stream_id}: state: #{inspect(state)}")

    time = current_stream_time(state.last_stream_time, state.last_event_time) || 0
    publish(state.stream_id, :end, %{time: time})
    update_schema(state, online: false)
    end_recording(state)

    :ok
  end

  def recording_mode, do: config(:recording, :allowed)

  # Private

  defp via_tuple(stream_id),
    do: {:via, Horde.Registry, {Asciinema.Streaming.StreamRegistry, stream_id}}

  defp update_base_stream_time(state, last_event_id, time) do
    if in_sync?(state, last_event_id) do
      state
    else
      %{state | base_stream_time: time}
    end
  end

  defp update_last_stream_time(state, time) do
    %{state | last_stream_time: time, last_event_time: Timex.now()}
  end

  defp update_schema(state, fields) do
    stream = Streaming.update_stream(state.stream, fields)

    %{state | stream: stream}
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

  defp reset_vt(state, cols, rows) do
    {:ok, vt} = Vt.new(cols, rows, 100)

    %{state | vt: vt, vt_size: {cols, rows}}
  end

  defp restart_recording(state, last_event_id, cols, rows, term_init, theme, query) do
    if in_sync?(state, last_event_id) do
      state
    else
      state
      |> end_recording()
      |> start_recording(cols, rows, term_init, theme, query)
    end
  end

  defp start_recording(state, cols, rows, term_init, theme, query) do
    mode = recording_mode()
    user = state.stream.user

    if mode == :forced or (mode == :allowed && user.stream_recording_enabled) do
      create_asciicast_v2_file(state, cols, rows, term_init, theme, query)
    else
      state
    end
  end

  defp end_recording(%{file: nil} = state), do: state

  defp end_recording(%{file: file} = state) do
    Logger.info("stream/#{state.stream_id}: creating recording")
    :ok = File.close(file)

    upload = %Plug.Upload{
      path: state.path,
      content_type: "application/x-asciicast",
      filename: "stream.cast"
    }

    fields = %{
      stream_id: state.stream_id,
      user_agent: state.user_agent
    }

    {:ok, _} = Recordings.create_asciicast(state.stream.user, upload, fields)
    File.rm(state.path)

    %{state | path: nil, file: nil}
  end

  defp create_asciicast_v2_file(state, cols, rows, term_init, theme, query) do
    path = Briefly.create!()
    file = File.open!(path, [:write, :utf8])
    state = %{state | path: path, file: file}
    timestamp = Timex.to_unix(Timex.now())
    env = drop_empty(query["env"] || %{})

    write_asciicast_v2_header(file, cols, rows, timestamp, env, theme)

    if term_init not in [nil, ""] do
      write_asciicast_v2_event(state, state.base_stream_time, "o", term_init)
    end

    state
  end

  defp write_asciicast_v2_header(file, cols, rows, timestamp, env, theme) do
    header =
      drop_empty(%{
        version: 2,
        width: cols,
        height: rows,
        timestamp: timestamp,
        env: env,
        theme: asciicast_theme(theme)
      })

    :ok = IO.write(file, Jason.encode!(header) <> "\n")
  end

  defp write_asciicast_v2_event(%{file: nil} = _state, _time, _type, _data), do: :ok

  defp write_asciicast_v2_event(%{file: file} = state, time, type, data) do
    time = serialize_time(time - state.base_stream_time)
    data = Jason.encode!(data)
    event = "[#{time}, \"#{type}\", #{data}]"
    :ok = IO.write(file, event <> "\n")
  end

  defp drop_empty(map) when is_map(map) do
    map
    |> Enum.filter(fn {_k, v} -> v != nil and v != "" and v != %{} end)
    |> Enum.into(%{})
  end

  defp in_sync?(state, last_event_id),
    do: last_event_id != 0 and last_event_id == state.last_event_id

  defp serialize_time(time) do
    whole = div(time, 1_000_000)

    decimal =
      time
      |> rem(1_000_000)
      |> to_string()
      |> String.pad_leading(6, "0")
      |> String.trim_trailing("0")

    decimal =
      case decimal do
        "" -> "0"
        d -> d
      end

    "#{whole}.#{decimal}"
  end

  defp save_event_id(state, id), do: %{state | last_event_id: id}

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

  defp schema_theme_fields(nil), do: [theme_fg: nil, theme_bg: nil, theme_palette: nil]

  defp schema_theme_fields(theme) do
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

  defp asciicast_theme(nil), do: nil

  defp asciicast_theme(theme) do
    palette =
      theme.palette
      |> Enum.map(&Colors.hex/1)
      |> Enum.join(":")

    %{
      fg: Colors.hex(theme.fg),
      bg: Colors.hex(theme.bg),
      palette: palette
    }
  end

  defp generate_snapshot(vt) do
    {:ok, {lines, cursor}} = Vt.dump_screen(vt)

    {lines, cursor}
  end
end
