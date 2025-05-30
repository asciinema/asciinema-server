defmodule Asciinema.Streaming.StreamServer do
  use GenServer, restart: :temporary
  use Asciinema.Config
  alias Asciinema.Recordings
  alias Asciinema.Recordings.Asciicast.V3
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
      base_stream_time: 0,
      last_stream_time: nil,
      last_event_time: nil,
      user_agent: nil,
      path: nil,
      writer: nil,
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
    term_type = get_in(query, ["term", "type"])
    term_version = get_in(query, ["term", "version"])
    env = query["env"] || %{}
    shell = query["shell"]
    title = query["title"]

    schema_changes =
      [
        online: true,
        last_started_at: last_started_at,
        term_cols: cols,
        term_rows: rows,
        term_type: term_type,
        term_version: term_version,
        user_agent: user_agent,
        shell: shell
      ]
      |> Keyword.merge(schema_theme_fields(theme))
      |> Keyword.merge(optional_fields(title))

    state =
      %{state | theme: theme, user_agent: user_agent}
      |> reset_vt(cols, rows)
      |> update_base_stream_time(last_id, time)
      |> update_last_stream_time(time)
      |> update_schema(schema_changes)

    state =
      state
      |> restart_recording(
        last_id,
        cols,
        rows,
        args[:term_init],
        term_type,
        term_version,
        theme,
        env,
        state.stream.title
      )
      |> save_event_id(last_id)

    if term_init = args[:term_init] do
      Vt.feed(state.vt, term_init)
    end

    publish(state.stream_id, :metadata, state.stream)
    publish(state.stream_id, :reset, args)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:output, data}}, _from, state) do
    %{id: id, time: time, text: text} = data
    Vt.feed(state.vt, text)
    publish(state.stream_id, :output, data)

    state =
      state
      |> write_asciicast_event(time, "o", text)
      |> update_last_stream_time(time)
      |> save_event_id(id)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:input, data}}, _from, state) do
    %{id: id, time: time, text: text} = data
    publish(state.stream_id, :input, data)

    state =
      state
      |> write_asciicast_event(time, "i", text)
      |> update_last_stream_time(time)
      |> save_event_id(id)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:resize, data}}, _from, state) do
    %{id: id, time: time, term_size: {cols, rows} = vt_size} = data
    Vt.resize(state.vt, cols, rows)
    publish(state.stream_id, :resize, data)

    state =
      state
      |> write_asciicast_event(time, "r", {cols, rows})
      |> update_last_stream_time(time)
      |> Map.put(:vt_size, vt_size)
      |> save_event_id(id)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:marker, data}}, _from, state) do
    %{id: id, time: time, label: label} = data
    publish(state.stream_id, :marker, data)

    state =
      state
      |> write_asciicast_event(time, "m", label)
      |> update_last_stream_time(time)
      |> save_event_id(id)

    {:reply, :ok, state}
  end

  def handle_call({:event, {:exit, data}}, _from, state) do
    %{id: id, time: time, status: status} = data
    publish(state.stream_id, :exit, data)

    state =
      state
      |> write_asciicast_event(time, "x", to_string(status))
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
        term_cols: cols,
        term_rows: rows,
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
    update_schema(state, online: false, current_viewer_count: 0)
    end_recording(state)

    :ok
  end

  def recording_mode, do: config(:recording, :allowed)

  # Private

  defp via_tuple(stream_id),
    do: {:via, Horde.Registry, {Asciinema.Streaming.StreamRegistry, stream_id}}

  defp update_base_stream_time(state, client_last_event_id, time) do
    if client_last_event_id == state.last_event_id do
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

  defp restart_recording(
         state,
         client_last_event_id,
         cols,
         rows,
         term_init,
         term_type,
         term_version,
         theme,
         env,
         title
       ) do
    if client_last_event_id == state.last_event_id and client_last_event_id != 0 do
      state
    else
      state
      |> end_recording()
      |> start_recording(cols, rows, term_init, term_type, term_version, theme, env, title)
    end
  end

  defp start_recording(state, cols, rows, term_init, term_type, term_version, theme, env, title) do
    mode = recording_mode()
    user = state.stream.user

    if mode == :forced or (mode == :allowed && user.stream_recording_enabled) do
      create_asciicast_file(
        state,
        cols,
        rows,
        term_init,
        term_type,
        term_version,
        theme,
        env,
        title
      )
    else
      state
    end
  end

  defp end_recording(%{writer: nil} = state), do: state

  defp end_recording(%{writer: writer} = state) do
    Logger.info("stream/#{state.stream_id}: creating recording")

    :ok = V3.close(writer)

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

    %{state | path: nil, writer: nil}
  end

  defp create_asciicast_file(
         state,
         cols,
         rows,
         term_init,
         term_type,
         term_version,
         theme,
         env,
         title
       ) do
    path = Briefly.create!()
    timestamp = Timex.to_unix(Timex.now())

    {:ok, writer} =
      V3.create(path, {cols, rows},
        term_type: term_type,
        term_version: term_version,
        term_theme: theme,
        env: env,
        title: title,
        timestamp: timestamp
      )

    if term_init not in [nil, ""] do
      {:ok, writer} = V3.write_event(writer, 0, "o", term_init)

      %{state | path: path, writer: writer}
    else
      %{state | path: path, writer: writer}
    end
  end

  defp write_asciicast_event(%{writer: nil} = state, _time, _type, _data), do: state

  defp write_asciicast_event(%{writer: writer} = state, time, type, data) do
    {:ok, writer} = V3.write_event(writer, time - state.base_stream_time, type, data)

    %{state | writer: writer}
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

  defp schema_theme_fields(nil),
    do: [term_theme_fg: nil, term_theme_bg: nil, term_theme_palette: nil]

  defp schema_theme_fields(theme) do
    palette =
      theme.palette
      |> Enum.map(&Colors.hex/1)
      |> Enum.join(":")

    [
      term_theme_fg: Colors.hex(theme.fg),
      term_theme_bg: Colors.hex(theme.bg),
      term_theme_palette: palette
    ]
  end

  defp optional_fields(nil), do: []
  defp optional_fields(title), do: [title: title]

  defp generate_snapshot(vt) do
    {:ok, {lines, cursor}} = Vt.dump_screen(vt)

    {lines, cursor}
  end
end
