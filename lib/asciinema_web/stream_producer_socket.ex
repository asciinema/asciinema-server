defmodule AsciinemaWeb.StreamProducerSocket do
  import Plug.Conn

  alias Asciinema.AppEnv
  alias Asciinema.Streaming
  alias Asciinema.Streaming.{ProducerSession, StreamServer, StreamSupervisor}
  require Logger

  @behaviour WebSock

  @ws_opts [compress: true]
  @parser_check_timeout 5_000
  @client_ping_interval 15_000
  @server_heartbeat_interval 15_000

  def upgrade(conn, %{"producer_token" => producer_token}) do
    params = %{token: producer_token, user_agent: user_agent(conn), protocol: nil}

    case requested_protocols(conn) do
      [] ->
        conn
        |> WebSockAdapter.upgrade(__MODULE__, params, @ws_opts)
        |> halt()

      protos ->
        case select_protocol(protos) do
          nil ->
            conn
            |> send_resp(400, "")
            |> halt()

          protocol ->
            conn
            |> put_resp_header("sec-websocket-protocol", protocol)
            |> WebSockAdapter.upgrade(__MODULE__, %{params | protocol: protocol}, @ws_opts)
            |> halt()
        end
    end
  end

  # WebSock callbacks

  @impl true
  def init(params) when is_map(params) do
    %{token: token, protocol: protocol, user_agent: user_agent} = params

    case Streaming.find_live_stream_by_producer_token(token) do
      nil ->
        handle_error({:stream_not_found, token}, %{stream_id: "?"})

      stream ->
        Logger.info("producer/#{stream.id}: connected")
        {session, effects} = ProducerSession.new(protocol, bucket_opts())

        state = %{
          stream_id: stream.id,
          user_agent: user_agent,
          session: session,
          heartbeat_token: nil
        }

        {:ok, state} = execute_effects(effects, state)
        Process.send_after(self(), :parser_check, @parser_check_timeout)
        Process.send_after(self(), :client_ping, @client_ping_interval)
        Process.send_after(self(), :bucket_fill, bucket_fill_interval())

        if protocol do
          Logger.info("producer/#{stream.id}: negotiated #{protocol} protocol")
        else
          Logger.info("producer/#{stream.id}: no protocol negotiated, will try to auto-detect")
        end

        {:ok, state}
    end
  end

  @impl true
  def handle_in({payload, opcode: opcode}, state) when opcode in [:text, :binary] do
    frame = {opcode, payload}
    now = System.system_time(:microsecond)
    newly_detected = not ProducerSession.parser_selected?(state.session)

    # drain the budget first: over-budget frames are rejected before parsing
    with {:ok, session} <- ProducerSession.drain_bucket(state.session, byte_size(payload)),
         {:ok, effects, session} <- ProducerSession.receive_frame(session, frame, now),
         :ok <- log_detection(newly_detected, session, state),
         {:ok, state} <- execute_effects(effects, state) do
      # the pending session is committed only on full success
      {:ok, %{state | session: session}}
    else
      {:error, reason} ->
        handle_error(reason, state)

      {:error, reason, effects} ->
        {:ok, state} = execute_effects(effects, state)

        handle_error(reason, state)
    end
  end

  def handle_in(_message, state), do: {:ok, state}

  defp log_detection(false, _session, _state), do: :ok

  defp log_detection(true, session, state) do
    Logger.info(
      "producer/#{state.stream_id}: detected #{ProducerSession.parser_name(session)} protocol"
    )
  end

  @impl true
  def handle_info(:client_ping, state) do
    Process.send_after(self(), :client_ping, @client_ping_interval)

    {:push, {:ping, ""}, state}
  end

  # a single heartbeat chain per stream start: each {:reset_stream, _} effect
  # mints a new token, orphaning any chain from a previous init
  def handle_info({:server_heartbeat, token}, %{heartbeat_token: token} = state) do
    if ProducerSession.online?(state.session) do
      Process.send_after(self(), {:server_heartbeat, token}, @server_heartbeat_interval)

      case StreamServer.heartbeat(state.stream_id) do
        :ok ->
          {:ok, state}

        {:error, reason} ->
          handle_error(reason, state)
      end
    else
      {:ok, state}
    end
  end

  def handle_info({:server_heartbeat, _stale_token}, state), do: {:ok, state}

  def handle_info(:parser_check, state) do
    if ProducerSession.parser_selected?(state.session) do
      {:ok, state}
    else
      handle_error(:header_timeout, state)
    end
  end

  def handle_info(:bucket_fill, state) do
    old_tokens = state.session.bucket.tokens
    session = ProducerSession.refill_bucket(state.session)
    tokens = session.bucket.tokens

    if tokens > old_tokens && tokens < session.bucket.size do
      Logger.debug("producer/#{state.stream_id}: fill to #{tokens}")
    end

    Process.send_after(self(), :bucket_fill, bucket_fill_interval())

    {:ok, %{state | session: session}}
  end

  @impl true
  def terminate(reason, state) do
    stream_id = state[:stream_id] || state[:token] || "?"
    Logger.info("producer/#{stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("producer/#{stream_id}: state: #{inspect(state)}")

    if reason == :remote && state[:session] && ProducerSession.stop_on_close?(state.session) &&
         state[:stream_id] do
      stop_server(state.stream_id)
    end

    :ok
  end

  # Effect execution

  defp execute_effects(effects, state) do
    Enum.reduce_while(effects, {:ok, state}, fn effect, {:ok, state} ->
      case execute_effect(effect, state) do
        {:ok, state} -> {:cont, {:ok, state}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp execute_effect({:persist_protocol, protocol}, state) do
    state.stream_id
    |> Streaming.get_stream()
    |> Streaming.update_stream(protocol: protocol)

    {:ok, state}
  end

  defp execute_effect({:reset_stream, args}, state) do
    %{term_size: {cols, rows}, time: time} = args
    Logger.info("producer/#{state.stream_id}: init (#{cols}x#{rows} @#{time / 1_000_000.0})")
    Logger.info("producer/#{state.stream_id}: stream went online, starting server")
    {:ok, _pid} = StreamSupervisor.ensure_child(state.stream_id)
    :ok = StreamServer.claim(state.stream_id)

    with :ok <- StreamServer.reset(state.stream_id, args, state.user_agent) do
      token = make_ref()
      Process.send_after(self(), {:server_heartbeat, token}, @server_heartbeat_interval)

      {:ok, %{state | heartbeat_token: token}}
    end
  end

  defp execute_effect({:stream_event, type, args}, state) do
    with :ok <- StreamServer.event(state.stream_id, type, args) do
      {:ok, state}
    end
  end

  defp execute_effect(:stop_stream, state) do
    stop_server(state.stream_id)

    {:ok, state}
  end

  defp stop_server(stream_id) do
    Logger.info("producer/#{stream_id}: stream ended, stopping the server")
    StreamServer.stop(stream_id)
  end

  # Private

  @default_bucket_fill_interval 100
  @default_bucket_fill_amount 10_000
  @default_bucket_size 60_000_000

  defp bucket_opts do
    [
      size: config(:bucket_size, @default_bucket_size),
      fill_amount: config(:bucket_fill_amount, @default_bucket_fill_amount)
    ]
  end

  defp bucket_fill_interval, do: config(:bucket_fill_interval, @default_bucket_fill_interval)

  defp handle_error(reason, state) do
    case reason do
      :ownership_lost ->
        Logger.info("producer/#{state.stream_id}: stream ownership lost")

        {:stop, :ownership_lost, {4002, "ownership lost"}, state}

      {:invalid_vt_size, {cols, rows}} ->
        Logger.info("producer/#{state.stream_id}: invalid vt size: #{cols}x#{rows}")

        {:stop, :invalid_terminal_size, {4003, "invalid terminal size (#{cols}x#{rows})"}, state}

      :bucket_empty ->
        Logger.info("producer/#{state.stream_id}: byte budget exceeded")

        {:stop, :bandwidth_exceeded, {4004, "bandwidth exceeded"}, state}

      {:invalid_command, command, phase} ->
        Logger.warning(
          "producer/#{state.stream_id}: #{command} command not allowed in #{phase} phase"
        )

        {:stop, :invalid_command, {4005, "message parsing error"}, state}

      {:parser, reason, message} ->
        Logger.warning("producer/#{state.stream_id}: parser error: #{inspect(reason)}")
        Logger.debug("producer/#{state.stream_id}: message: #{inspect(message)}")

        {:stop, :message_parsing_error, {4005, "message parsing error"}, state}

      {:stream_not_found, token} ->
        Logger.warning("producer: stream not found for producer token #{token}")
        :timer.sleep(1000)

        {:stop, :stream_not_found, {4040, "stream not found"}, state}

      :header_timeout ->
        Logger.info("producer/#{state.stream_id}: header timeout")

        {:stop, :header_timeout, {4101, "header timeout"}, state}
    end
  end

  @protos ~w(v1.alis v2.asciicast v3.asciicast raw)

  defp select_protocol(protos) do
    # Choose common protos between the client and the server using client preferred order.
    common = protos -- (protos -- @protos)

    List.first(common)
  end

  defp requested_protocols(conn) do
    conn
    |> get_req_header("sec-websocket-protocol")
    |> Enum.flat_map(&Plug.Conn.Utils.list/1)
  end

  defp user_agent(conn) do
    conn
    |> get_req_header("user-agent")
    |> List.first()
  end

  defp config(key, default) do
    AppEnv.get(:"stream_producer_#{key}", default)
  end
end
