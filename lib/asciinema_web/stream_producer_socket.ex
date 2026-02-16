defmodule AsciinemaWeb.StreamProducerSocket do
  import Plug.Conn

  alias Asciinema.Streaming
  alias Asciinema.Streaming.{Parser, StreamServer, StreamSupervisor}
  require Logger

  @behaviour WebSock

  @ws_opts [compress: true]
  @parser_check_timeout 5_000
  @client_ping_interval 15_000
  @server_heartbeat_interval 15_000

  def upgrade(conn, %{"producer_token" => producer_token}) do
    params = %{token: producer_token, user_agent: user_agent(conn), parser: nil}

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
            parser = Parser.get(protocol)

            conn
            |> put_resp_header("sec-websocket-protocol", protocol)
            |> WebSockAdapter.upgrade(__MODULE__, %{params | parser: parser}, @ws_opts)
            |> halt()
        end
    end
  end

  # WebSock callbacks

  @impl true
  def init(params) when is_map(params) do
    %{token: token, parser: parser, user_agent: user_agent} = params

    case Streaming.find_live_stream_by_producer_token(token) do
      nil ->
        handle_error({:stream_not_found, token}, %{stream_id: "?"})

      stream ->
        Logger.info("producer/#{stream.id}: connected")
        state = set_parser(build_state(stream.id, user_agent), parser)
        Process.send_after(self(), :parser_check, @parser_check_timeout)
        Process.send_after(self(), :client_ping, @client_ping_interval)
        Process.send_after(self(), :bucket_fill, state.bucket.fill_interval)
        Process.send_after(self(), :server_heartbeat, @server_heartbeat_interval)

        if parser do
          Logger.info("producer/#{stream.id}: negotiated #{parser.impl.name()} protocol")
        else
          Logger.info("producer/#{stream.id}: no protocol negotiated, will try to auto-detect")
        end

        {:ok, state}
    end
  end

  @impl true
  def handle_in(frame, state)

  def handle_in(message, %{parser: nil} = state) do
    parser = Parser.get(detect_protocol(message))
    Logger.info("producer/#{state.stream_id}: detected #{parser.impl.name()} protocol")
    state = set_parser(state, parser)
    handle_in(message, state)
  end

  def handle_in({payload, opcode: opcode}, %{parser: parser} = state)
      when opcode in [:text, :binary] do
    message = {opcode, payload}

    with {:ok, commands, new_parser_state} <- run_parser(parser, message),
         {:ok, state} <- run_commands(commands, state),
         {:ok, state} <- drain_bucket(state, byte_size(payload)) do
      {:ok, put_in(state, [:parser, :state], new_parser_state)}
    else
      {:error, reason} ->
        handle_error(reason, state)
    end
  end

  def handle_in(_message, state), do: {:ok, state}

  @impl true
  def handle_info(:client_ping, state) do
    Process.send_after(self(), :client_ping, @client_ping_interval)

    {:push, {:ping, ""}, state}
  end

  def handle_info(:server_heartbeat, %{status: :online} = state) do
    Process.send_after(self(), :server_heartbeat, @server_heartbeat_interval)

    case StreamServer.heartbeat(state.stream_id) do
      :ok ->
        {:ok, state}

      {:error, reason} ->
        handle_error(reason, state)
    end
  end

  def handle_info(:server_heartbeat, state), do: {:ok, state}

  def handle_info(:parser_check, %{parser: nil} = state),
    do: handle_error(:header_timeout, state)

  def handle_info(:parser_check, state), do: {:ok, state}

  def handle_info(:bucket_fill, state) do
    bucket = state.bucket
    tokens = min(bucket.size, bucket.tokens + bucket.fill_amount)

    if tokens > bucket.tokens && tokens < bucket.size do
      Logger.debug("producer/#{state.stream_id}: fill to #{tokens}")
    end

    Process.send_after(self(), :bucket_fill, bucket.fill_interval)

    {:ok, put_in(state, [:bucket, :tokens], tokens)}
  end

  @impl true
  def terminate(reason, state) do
    stream_id = state[:stream_id] || state[:token] || "?"
    Logger.info("producer/#{stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("producer/#{stream_id}: state: #{inspect(state)}")

    if reason == :remote && state.stop_server_on_terminate && state[:stream_id] do
      StreamServer.stop(state.stream_id)
    end

    :ok
  end

  # Private

  @default_bucket_fill_interval 100
  @default_bucket_fill_amount 10_000
  @default_bucket_size 60_000_000

  defp build_state(stream_id, user_agent) do
    %{
      stream_id: stream_id,
      status: :new,
      user_agent: user_agent,
      parser: nil,
      stop_server_on_terminate: nil,
      bucket: %{
        size: config(:bucket_size, @default_bucket_size),
        tokens: config(:bucket_size, @default_bucket_size),
        fill_interval: config(:bucket_fill_interval, @default_bucket_fill_interval),
        fill_amount: config(:bucket_fill_amount, @default_bucket_fill_amount)
      }
    }
  end

  defp set_parser(state, parser) do
    if parser do
      save_protocol(state.stream_id, parser.impl.name())
    end

    # for protocols that support EOT (alis) we stop the stream server upon
    # receiving the :eot command, for the rest we stop the server in
    # terminate/2
    stop = if parser, do: :eot not in parser.impl.supported_commands()

    %{state | parser: parser, stop_server_on_terminate: stop}
  end

  defp run_parser(%{impl: impl, state: state}, message) do
    with {:error, reason} <- impl.parse(message, state) do
      {:error, {:parser, reason, message}}
    end
  end

  defp run_commands(commands, state) do
    Enum.reduce(commands, {:ok, state}, fn command, prev_result ->
      with {:ok, state} <- prev_result do
        run_command(command, state)
      end
    end)
  end

  @max_cols 720
  @max_rows 200

  defp run_command({:init, %{term_size: {cols, rows}, time: time} = args}, %{status: s} = state)
       when s != :online do
    Logger.info("producer/#{state.stream_id}: init (#{cols}x#{rows} @#{time / 1_000_000.0})")

    if cols > 0 and rows > 0 and cols <= @max_cols and rows <= @max_rows do
      ensure_server(state.stream_id)

      with :ok <- StreamServer.reset(state.stream_id, args, state.user_agent) do
        {:ok, %{state | status: :online}}
      end
    else
      {:error, {:invalid_vt_size, {cols, rows}}}
    end
  end

  defp run_command({:output, args}, %{status: :online} = state) do
    with :ok <- StreamServer.event(state.stream_id, :output, args) do
      {:ok, state}
    end
  end

  defp run_command({:input, args}, %{status: :online} = state) do
    with :ok <- StreamServer.event(state.stream_id, :input, args) do
      {:ok, state}
    end
  end

  defp run_command({:resize, %{term_size: {cols, rows}} = args}, state)
       when cols > 0 and rows > 0 and cols <= @max_cols and rows <= @max_rows do
    with :ok <- StreamServer.event(state.stream_id, :resize, args) do
      {:ok, state}
    end
  end

  defp run_command({:resize, %{term_size: size}}, _state), do: {:error, {:invalid_vt_size, size}}

  defp run_command({:marker, args}, %{status: :online} = state) do
    with :ok <- StreamServer.event(state.stream_id, :marker, args) do
      {:ok, state}
    end
  end

  defp run_command({:exit, args}, %{status: :online} = state) do
    with :ok <- StreamServer.event(state.stream_id, :exit, args) do
      # we got :exit, stopping the stream server in terminate/2 is ok at this
      # point, regardless of EOT support in the protocol
      state = %{state | stop_server_on_terminate: true}

      {:ok, state}
    end
  end

  defp run_command({:eot, _}, %{status: :online} = state) do
    stop_server(state.stream_id)

    {:ok, %{state | status: :eot, stop_server_on_terminate: false}}
  end

  defp ensure_server(%{status: :online} = state), do: state

  defp ensure_server(stream_id) do
    Logger.info("producer/#{stream_id}: stream went online, starting server")
    {:ok, _pid} = StreamSupervisor.ensure_child(stream_id)
    :ok = StreamServer.claim(stream_id)
    Process.send_after(self(), :server_heartbeat, @server_heartbeat_interval)
  end

  defp stop_server(stream_id) do
    Logger.info("producer/#{stream_id}: stream ended, stopping the server")
    StreamServer.stop(stream_id)
  end

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

      {:parser, reason, message} ->
        Logger.warning("producer/#{state.stream_id}: parser error: #{reason}")
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

  defp drain_bucket(state, drain_amount) do
    tokens = state.bucket.tokens - drain_amount

    if tokens < 0 do
      {:error, :bucket_empty}
    else
      {:ok, put_in(state, [:bucket, :tokens], tokens)}
    end
  end

  @protos ~w(v1.alis v2.asciicast v3.asciicast raw)

  defp select_protocol(protos) do
    # Choose common protos between the client and the server using client preferred order.
    common = protos -- (protos -- @protos)

    List.first(common)
  end

  def detect_protocol({:binary, "ALiS\x01"}), do: "v1.alis"
  def detect_protocol({:binary, _}), do: "raw"

  def detect_protocol({:text, header}) do
    case Jason.decode(header) do
      {:ok, %{"version" => 2}} -> "v2.asciicast"
      {:ok, %{"version" => 3}} -> "v3.asciicast"
      _otherwise -> "raw"
    end
  end

  def detect_protocol({payload, opcode: :binary}), do: detect_protocol({:binary, payload})
  def detect_protocol({payload, opcode: :text}), do: detect_protocol({:text, payload})

  defp save_protocol(stream_id, protocol) do
    stream_id
    |> Streaming.get_stream()
    |> Streaming.update_stream(protocol: protocol)
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
    Application.get_env(:asciinema, :"stream_producer_#{key}", default)
  end
end
