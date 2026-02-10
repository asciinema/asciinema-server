defmodule AsciinemaWeb.StreamConsumerSocket do
  import Plug.Conn

  alias Asciinema.{Accounts, Leb128, Streaming}
  alias Asciinema.Streaming.{StreamServer, ViewerTracker}
  alias AsciinemaWeb.Authorization
  require Logger

  @behaviour WebSock

  @protocol "v1.alis"
  @client_ping_interval 15_000

  def upgrade(conn, %{"public_token" => public_token}) do
    protocol = negotiated_protocol(conn)

    params = %{
      token: public_token,
      user_id: user_id_from_session(conn),
      stream_id: nil,
      protocol: protocol
    }

    if protocol do
      conn
      |> put_resp_header("sec-websocket-protocol", @protocol)
      |> do_upgrade(params, compress: true)
    else
      do_upgrade(conn, params, compress: false)
    end
  end

  defp do_upgrade(conn, params, opts) do
    conn
    |> WebSockAdapter.upgrade(__MODULE__, params, opts)
    |> halt()
  end

  # WebSock callbacks

  @impl true
  def init(%{protocol: nil} = state) do
    {:stop, :protocol_negotiation_failed, {1002, "protocol negotiation failed"}, state}
  end

  def init(%{token: token, user_id: user_id}) do
    with {:ok, stream} <- fetch_stream(token),
         :ok <- authorize(stream, user_id) do
      Logger.info("consumer/#{stream.id}: connected")
      state = %{stream_id: stream.id, init: false, last_event_time: 0.0}
      StreamServer.subscribe(stream.id, [:output, :input, :resize, :marker, :end, :reset])
      StreamServer.request_info(stream.id)
      ViewerTracker.track(stream.id)
      Process.send_after(self(), :client_ping, @client_ping_interval)

      {:push, magic_string(), state}
    else
      {:error, :stream_not_found} ->
        Logger.warning("consumer: stream not found for public token #{token}")
        :timer.sleep(1000)

        {:stop, :normal, %{stream_id: "?"}}

      {:error, :forbidden} ->
        Logger.warning("consumer: unauthorized connection attempt")

        {:stop, :normal, %{stream_id: token}}
    end
  end

  @impl true
  def handle_in(_frame, state), do: {:ok, state}

  @impl true
  def handle_info(message, state)

  def handle_info(%StreamServer.Update{event: :reset} = update, state) do
    %{term_size: {cols, rows}} = update.data
    Logger.debug("consumer/#{state.stream_id}: init (#{cols}x#{rows})")

    {:push,
     serialize_init(
       update.data.last_id,
       update.data.time,
       update.data.term_size,
       update.data[:term_init],
       update.data[:term_theme]
     ), %{state | init: true, last_event_time: update.data.time}}
  end

  def handle_info(%StreamServer.Update{event: :info} = update, %{init: false} = state) do
    %{term_size: {cols, rows}} = update.data
    Logger.debug("consumer/#{state.stream_id}: info (#{cols}x#{rows})")

    {:push,
     serialize_init(
       update.data.last_id,
       update.data.time,
       update.data.term_size,
       update.data.term_init,
       update.data.term_theme
     ), %{state | init: true, last_event_time: update.data.time}}
  end

  def handle_info(%StreamServer.Update{event: :info}, state) do
    {:ok, state}
  end

  def handle_info(%StreamServer.Update{}, %{init: false} = state) do
    {:ok, state}
  end

  def handle_info(%StreamServer.Update{event: :output} = update, state) do
    %{id: id, time: time, text: text} = update.data
    rel_time = time - state.last_event_time
    msg = serialize_output(id, rel_time, text)
    state = %{state | last_event_time: time}

    {:push, msg, state}
  end

  def handle_info(%StreamServer.Update{event: :input} = update, state) do
    %{id: id, time: time, text: text} = update.data
    rel_time = time - state.last_event_time
    msg = serialize_input(id, rel_time, text)
    state = %{state | last_event_time: time}

    {:push, msg, state}
  end

  def handle_info(%StreamServer.Update{event: :resize} = update, state) do
    %{id: id, time: time, term_size: term_size} = update.data
    rel_time = time - state.last_event_time
    msg = serialize_resize(id, rel_time, term_size)
    state = %{state | last_event_time: time}

    {:push, msg, state}
  end

  def handle_info(%StreamServer.Update{event: :marker} = update, state) do
    %{id: id, time: time, label: label} = update.data
    rel_time = time - state.last_event_time
    msg = serialize_marker(id, rel_time, label)
    state = %{state | last_event_time: time}

    {:push, msg, state}
  end

  def handle_info(%StreamServer.Update{event: :end} = update, state) do
    %{time: time} = update.data
    rel_time = time - state.last_event_time
    msg = serialize_eot(rel_time)
    state = %{state | last_event_time: time}

    {:push, msg, state}
  end

  def handle_info(:client_ping, state) do
    Process.send_after(self(), :client_ping, @client_ping_interval)

    {:push, {:ping, ""}, state}
  end

  @impl true
  def terminate(reason, state) do
    stream_id = state[:stream_id] || state[:token] || "?"
    Logger.info("consumer/#{stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("consumer/#{stream_id}: state: #{inspect(state)}")

    if stream_id = state[:stream_id] do
      ViewerTracker.untrack(stream_id)
    end

    :ok
  end

  # Private

  defp user_id_from_session(conn) do
    conn
    |> fetch_session()
    |> get_session("user_id")
  end

  defp fetch_stream(token) do
    case Streaming.lookup_stream(token) do
      nil -> {:error, :stream_not_found}
      stream -> {:ok, stream}
    end
  end

  defp authorize(stream, user_id) do
    if Authorization.can?(nil, :show, stream) ||
         (user_id && Authorization.can?(Accounts.get_user(user_id), :show, stream)) do
      :ok
    else
      {:error, :forbidden}
    end
  end

  defp requested_protocols(conn) do
    conn
    |> get_req_header("sec-websocket-protocol")
    |> Enum.flat_map(&Plug.Conn.Utils.list/1)
  end

  defp negotiated_protocol(conn) do
    if Enum.member?(requested_protocols(conn), @protocol), do: @protocol
  end

  defp magic_string, do: {:binary, "ALiS\x01"}

  defp serialize_init(id, time, term_size, term_init, theme) do
    {cols, rows} = term_size
    term_init = term_init || ""

    msg =
      <<1::8>> <>
        encode_varint(id) <>
        encode_varint(time) <>
        encode_varint(cols) <>
        encode_varint(rows) <>
        serialize_theme(theme) <>
        serialize_string(term_init)

    {:binary, msg}
  end

  defp serialize_output(id, time, text) do
    msg = <<?o>> <> encode_varint(id) <> encode_varint(time) <> serialize_string(text)

    {:binary, msg}
  end

  defp serialize_input(id, time, text) do
    msg = <<?i>> <> encode_varint(id) <> encode_varint(time) <> serialize_string(text)

    {:binary, msg}
  end

  defp serialize_resize(id, time, term_size) do
    {cols, rows} = term_size

    msg =
      <<?r>> <>
        encode_varint(id) <> encode_varint(time) <> encode_varint(cols) <> encode_varint(rows)

    {:binary, msg}
  end

  defp serialize_marker(id, time, label) do
    msg = <<?m>> <> encode_varint(id) <> encode_varint(time) <> serialize_string(label)

    {:binary, msg}
  end

  defp serialize_eot(time) do
    msg = <<0x04::8>> <> encode_varint(time)

    {:binary, msg}
  end

  defp encode_varint(value), do: Leb128.encode(value)

  defp serialize_string(text), do: encode_varint(byte_size(text)) <> text

  defp serialize_theme(nil), do: <<0::8>>

  defp serialize_theme(theme) do
    format = length(theme.palette)
    true = format in [8, 16]

    <<format::8>> <> do_serialize_theme(theme)
  end

  defp do_serialize_theme(%{fg: fg, bg: bg, palette: palette}) do
    for {r, g, b} <- [fg, bg | palette], into: <<>> do
      <<r::8, g::8, b::8>>
    end
  end
end
