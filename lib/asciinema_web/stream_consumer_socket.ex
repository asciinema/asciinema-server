defmodule AsciinemaWeb.StreamConsumerSocket do
  alias Asciinema.{Accounts, Authorization, Leb128, Streaming}
  alias Asciinema.Streaming.{StreamServer, ViewerTracker}
  alias AsciinemaWeb.Endpoint
  require Logger

  @behaviour :cowboy_websocket

  @protocol "v1.alis"
  @client_ping_interval 15_000

  # Callbacks

  @impl true
  def init(req, _opts) do
    params = %{
      token: req.bindings[:public_token],
      user_id: user_id_from_session(req),
      stream_id: nil,
      protocol: nil
    }

    case :cowboy_req.parse_header("sec-websocket-protocol", req) do
      :undefined ->
        {:cowboy_websocket, req, params}

      protos ->
        if Enum.member?(protos, @protocol) do
          req = :cowboy_req.set_resp_header("sec-websocket-protocol", @protocol, req)
          {:cowboy_websocket, req, %{params | protocol: @protocol}, %{compress: true}}
        else
          {:cowboy_websocket, req, params}
        end
    end
  end

  @impl true
  def websocket_init(%{protocol: nil} = state) do
    {:reply, {:close, 1002, "protocol negotiation failed"}, state}
  end

  def websocket_init(%{token: token, user_id: user_id}) do
    with {:ok, stream} <- fetch_stream(token),
         :ok <- authorize(stream, user_id) do
      Logger.info("consumer/#{stream.id}: connected")
      state = %{stream_id: stream.id, init: false, last_event_time: 0.0}
      StreamServer.subscribe(stream.id, [:output, :input, :resize, :marker, :end, :reset])
      StreamServer.request_info(stream.id)
      ViewerTracker.track(stream.id)
      Process.send_after(self(), :client_ping, @client_ping_interval)

      {:reply, magic_string(), state}
    else
      {:error, :stream_not_found} ->
        Logger.warning("consumer: stream not found for public token #{token}")
        :timer.sleep(1000)

        {:reply, :close, %{stream_id: "?"}}

      {:error, :forbidden} ->
        Logger.warning("consumer: unauthorized connection attempt")

        {:reply, :close, %{stream_id: token}}
    end
  end

  @impl true
  def websocket_handle(_frame, state), do: {:ok, state}

  @impl true
  def websocket_info(message, state)

  def websocket_info(%StreamServer.Update{event: :reset} = update, state) do
    %{term_size: {cols, rows}} = update.data
    Logger.debug("consumer/#{state.stream_id}: init (#{cols}x#{rows})")

    {:reply,
     serialize_init(
       update.data.last_id,
       update.data.time,
       update.data.term_size,
       update.data[:term_init],
       update.data[:term_theme]
     ), %{state | init: true, last_event_time: update.data.time}}
  end

  def websocket_info(%StreamServer.Update{event: :info} = update, %{init: false} = state) do
    %{term_size: {cols, rows}} = update.data
    Logger.debug("consumer/#{state.stream_id}: info (#{cols}x#{rows})")

    {:reply,
     serialize_init(
       update.data.last_id,
       update.data.time,
       update.data.term_size,
       update.data.term_init,
       update.data.term_theme
     ), %{state | init: true, last_event_time: update.data.time}}
  end

  def websocket_info(%StreamServer.Update{event: :info}, state) do
    {:ok, state}
  end

  def websocket_info(%StreamServer.Update{}, %{init: false} = state) do
    {:ok, state}
  end

  def websocket_info(%StreamServer.Update{event: :output} = update, state) do
    %{id: id, time: time, text: text} = update.data
    rel_time = time - state.last_event_time
    msg = serialize_output(id, rel_time, text)
    state = %{state | last_event_time: time}

    {:reply, msg, state}
  end

  def websocket_info(%StreamServer.Update{event: :input} = update, state) do
    %{id: id, time: time, text: text} = update.data
    rel_time = time - state.last_event_time
    msg = serialize_input(id, rel_time, text)
    state = %{state | last_event_time: time}

    {:reply, msg, state}
  end

  def websocket_info(%StreamServer.Update{event: :resize} = update, state) do
    %{id: id, time: time, term_size: term_size} = update.data
    rel_time = time - state.last_event_time
    msg = serialize_resize(id, rel_time, term_size)
    state = %{state | last_event_time: time}

    {:reply, msg, state}
  end

  def websocket_info(%StreamServer.Update{event: :marker} = update, state) do
    %{time: time, label: label} = update.data
    rel_time = time - state.last_event_time
    msg = serialize_marker(rel_time, label)
    state = %{state | last_event_time: time}

    {:reply, msg, state}
  end

  def websocket_info(%StreamServer.Update{event: :end} = update, state) do
    %{time: time} = update.data
    rel_time = time - state.last_event_time
    msg = serialize_eot(rel_time)
    state = %{state | last_event_time: time}

    {:reply, msg, state}
  end

  def websocket_info(:client_ping, state) do
    Process.send_after(self(), :client_ping, @client_ping_interval)

    {:reply, :ping, state}
  end

  @impl true
  def terminate(reason, _req, state) do
    stream_id = state[:stream_id] || state[:token] || "?"
    Logger.info("consumer/#{stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("consumer/#{stream_id}: state: #{inspect(state)}")

    if stream_id = state[:stream_id] do
      ViewerTracker.untrack(stream_id)
    end

    :ok
  end

  # Private

  @session_key Keyword.fetch!(Application.compile_env!(:asciinema, :session_opts), :key)
  @signing_salt Keyword.fetch!(Application.compile_env!(:asciinema, :session_opts), :signing_salt)

  defp user_id_from_session(req) do
    cookies = :cowboy_req.parse_cookies(req)

    with {_, cookie} <- List.keyfind(cookies, @session_key, 0) do
      secret_key_base = Application.fetch_env!(:asciinema, Endpoint)[:secret_key_base]
      conn = %{secret_key_base: secret_key_base}
      opts = Plug.Session.COOKIE.init(signing_salt: @signing_salt)
      {:term, session} = Plug.Session.COOKIE.get(conn, cookie, opts)

      session["user_id"]
    end
  end

  defp fetch_stream(token) do
    case Streaming.get_stream(token) do
      nil -> {:error, :stream_not_found}
      stream -> {:ok, stream}
    end
  end

  defp authorize(stream, user_id) do
    if Authorization.can?(nil, :show, stream) ||
         Authorization.can?(Accounts.get_user(user_id), :show, stream) do
      :ok
    else
      {:error, :forbidden}
    end
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

  defp serialize_marker(time, label) do
    msg = <<?m>> <> encode_varint(time) <> serialize_string(label)

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
