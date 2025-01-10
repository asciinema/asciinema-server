defmodule AsciinemaWeb.LiveStreamProducerSocket do
  alias Asciinema.Streaming
  alias Asciinema.Streaming.{LiveStreamServer, LiveStreamSupervisor, Parser}
  require Logger

  @behaviour :cowboy_websocket

  @parser_check_timeout 5_000
  @client_ping_interval 15_000
  @server_heartbeat_interval 15_000

  # Callbacks

  @impl true
  def init(req, _opts),
    do: {:cowboy_websocket, req, req.bindings[:producer_token], %{compress: true}}

  @impl true
  def websocket_init(token) do
    case Streaming.find_live_stream_by_producer_token(token) do
      nil ->
        handle_error({:stream_not_found, token}, %{stream_id: "?"})

      stream ->
        Logger.info("producer/#{stream.id}: connected")
        state = build_state(stream.id)
        Process.send_after(self(), :parser_check, @parser_check_timeout)
        Process.send_after(self(), :client_ping, @client_ping_interval)
        Process.send_after(self(), :bucket_fill, state.bucket.fill_interval)
        Process.send_after(self(), :server_heartbeat, @server_heartbeat_interval)

        {:ok, state}
    end
  end

  @impl true
  def websocket_handle(frame, state)

  def websocket_handle({:binary, "ALiS" <> _} = message, %{parser: nil} = state) do
    Logger.info("producer/#{state.stream_id}: activating ALiS parser")
    save_parser(state.stream_id, "alis")
    websocket_handle(message, %{state | parser: Parser.get(:alis)})
  end

  def websocket_handle({:binary, _} = message, %{parser: nil} = state) do
    Logger.info("producer/#{state.stream_id}: activating raw text parser")
    save_parser(state.stream_id, "raw")
    websocket_handle(message, %{state | parser: Parser.get(:raw)})
  end

  def websocket_handle({:text, _} = message, %{parser: nil} = state) do
    Logger.info("producer/#{state.stream_id}: activating json parser")
    save_parser(state.stream_id, "json")
    websocket_handle(message, %{state | parser: Parser.get(:json)})
  end

  def websocket_handle({_, payload} = message, %{parser: parser} = state) do
    with {:ok, commands, new_parser_state} <- run_parser(parser, message),
         {:ok, state} <- run_commands(commands, state),
         {:ok, state} <- drain_bucket(state, byte_size(payload)) do
      {:ok, put_in(state, [:parser, :state], new_parser_state)}
    else
      {:error, reason} ->
        handle_error(reason, state)
    end
  end

  def websocket_handle(_message, state), do: {:ok, state}

  @impl true
  def websocket_info(:client_ping, state) do
    Process.send_after(self(), :client_ping, @client_ping_interval)

    {:reply, :ping, state}
  end

  def websocket_info(:server_heartbeat, state) do
    Process.send_after(self(), :server_heartbeat, @server_heartbeat_interval)

    case state do
      %{status: :online} ->
        case LiveStreamServer.heartbeat(state.stream_id) do
          :ok ->
            {:ok, state}

          {:error, reason} ->
            handle_error(reason, state)
        end

      _ ->
        {:ok, state}
    end
  end

  def websocket_info(:parser_check, %{parser: nil} = state),
    do: handle_error(:header_timeout, state)

  def websocket_info(:parser_check, state), do: {:ok, state}

  def websocket_info(:bucket_fill, state) do
    bucket = state.bucket
    tokens = min(bucket.size, bucket.tokens + bucket.fill_amount)

    if tokens > bucket.tokens && tokens < bucket.size do
      Logger.debug("producer/#{state.stream_id}: fill to #{tokens}")
    end

    Process.send_after(self(), :bucket_fill, bucket.fill_interval)

    {:ok, put_in(state, [:bucket, :tokens], tokens)}
  end

  @impl true
  def terminate(reason, _req, state) do
    Logger.info("producer/#{state.stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("producer/#{state.stream_id}: state: #{inspect(state)}")

    if reason == :remote || match?({:remote, _, _}, reason) do
      LiveStreamServer.stop(state.stream_id)
    end

    :ok
  end

  # Private

  @default_bucket_fill_interval 100
  @default_bucket_fill_amount 10_000
  @default_bucket_size 60_000_000

  defp build_state(stream_id) do
    %{
      stream_id: stream_id,
      status: :new,
      parser: nil,
      bucket: %{
        size: config(:bucket_size, @default_bucket_size),
        tokens: config(:bucket_size, @default_bucket_size),
        fill_interval: config(:bucket_fill_interval, @default_bucket_fill_interval),
        fill_amount: config(:bucket_fill_amount, @default_bucket_fill_amount)
      }
    }
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

  defp run_command({:reset, %{size: {cols, rows}} = params}, state)
       when cols > 0 and rows > 0 and cols <= @max_cols and rows <= @max_rows do
    Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")

    state = ensure_server(state)

    with :ok <-
           LiveStreamServer.reset(
             state.stream_id,
             {cols, rows},
             params[:init],
             params[:time],
             params[:theme]
           ) do
      {:ok, state}
    end
  end

  defp run_command({:reset, %{size: size}}, _state) do
    {:error, {:invalid_vt_size, size}}
  end

  defp run_command({:output, args}, %{status: :online} = state) do
    with :ok <- LiveStreamServer.output(state.stream_id, args) do
      {:ok, state}
    end
  end

  defp run_command({:resize, {_time, {cols, rows}} = args}, state)
       when cols > 0 and rows > 0 and cols <= @max_cols and rows <= @max_rows do
    with :ok <- LiveStreamServer.resize(state.stream_id, args) do
      {:ok, state}
    end
  end

  defp run_command({:resize, {_time, size}}, _state), do: {:error, {:invalid_vt_size, size}}

  defp run_command({:status, :offline}, %{status: :new} = state), do: {:ok, state}

  defp run_command({:status, :offline}, %{status: :online} = state) do
    Logger.info("producer/#{state.stream_id}: stream went offline, stopping server")
    LiveStreamServer.stop(state.stream_id)

    {:ok, %{state | status: :offline}}
  end

  defp ensure_server(%{status: :online} = state), do: state

  defp ensure_server(state) do
    Logger.info("producer/#{state.stream_id}: stream went online, starting server")
    {:ok, _pid} = LiveStreamSupervisor.ensure_child(state.stream_id)
    :ok = LiveStreamServer.lead(state.stream_id)
    Process.send_after(self(), :server_heartbeat, @server_heartbeat_interval)

    %{state | status: :online}
  end

  defp handle_error(reason, state) do
    case reason do
      :leadership_lost ->
        Logger.info("producer/#{state.stream_id}: leadership lost")

        {:reply, {:close, 4002, "leadership lost"}, state}

      {:invalid_vt_size, {cols, rows}} ->
        Logger.info("producer/#{state.stream_id}: invalid vt size: #{cols}x#{rows}")

        {:reply, {:close, 4003, "invalid terminal size (#{cols}x#{rows})"}, state}

      :bucket_empty ->
        Logger.info("producer/#{state.stream_id}: byte budget exceeded")

        {:reply, {:close, 4004, "bandwidth exceeded"}, state}

      {:parser, reason, message} ->
        Logger.warn("producer/#{state.stream_id}: parser error: #{reason}")
        Logger.debug("producer/#{state.stream_id}: message: #{inspect(message)}")

        {:reply, {:close, 4005, "message parsing error"}, state}

      {:stream_not_found, token} ->
        Logger.warn("producer: stream not found for producer token #{token}")
        :timer.sleep(1000)

        {:reply, {:close, 4040, "stream not found"}, state}

      :header_timeout ->
        Logger.info("producer/#{state.stream_id}: header timeout")

        {:reply, {:close, 4101, "header timeout"}, state}
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

  defp save_parser(stream_id, parser_name) do
    Task.Supervisor.start_child(Asciinema.TaskSupervisor, fn ->
      stream_id
      |> Streaming.get_live_stream()
      |> Streaming.update_live_stream(parser: parser_name)
    end)
  end

  defp config(key, default) do
    Application.get_env(:asciinema, :"live_stream_producer_#{key}", default)
  end
end
