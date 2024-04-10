defmodule AsciinemaWeb.LiveStreamProducerSocket do
  alias Asciinema.Streaming
  alias Asciinema.Streaming.{LiveStreamServer, LiveStreamSupervisor, Parser}
  require Logger

  @behaviour Phoenix.Socket.Transport

  @parser_check_timeout 5_000
  @ping_interval 15_000
  @heartbeat_interval 15_000
  @default_bucket_fill_interval 100
  @default_bucket_fill_amount 10_000
  @default_bucket_size 60_000_000

  # Callbacks

  @impl true
  def child_spec(_opts) do
    # We won't spawn any process, so let's return a dummy task
    %{id: __MODULE__, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  @impl true
  def connect(state) do
    token = state.params["producer_token"]

    case Streaming.find_live_stream_by_producer_token(token) do
      nil ->
        Logger.warn("producer: stream not found for producer token #{token}")
        :timer.sleep(1000)

        :error

      stream ->
        state = %{
          stream_id: stream.id,
          status: :new,
          parser: nil,
          bucket: %{
            size: config(:bucket_size, @default_bucket_size),
            tokens: config(:bucket_size, @default_bucket_size),
            fill_interval: config(:bucket_fill_interval, @default_bucket_fill_interval),
            fill_amount: config(:bucket_fill_amount, @default_bucket_fill_amount)
          }
        }

        {:ok, state}
    end
  end

  @impl true
  def init(state) do
    Logger.info("producer/#{state.stream_id}: connected")
    Process.send_after(self(), :parser_check, @parser_check_timeout)
    Process.send_after(self(), :ping, @ping_interval)
    Process.send_after(self(), :fill_bucket, state.bucket.fill_interval)
    Process.send_after(self(), :heartbeat, @heartbeat_interval)

    {:ok, state}
  end

  @impl true
  def handle_in({"ALiS" <> _, [opcode: :binary]} = message, %{parser: nil} = state) do
    Logger.info("producer/#{state.stream_id}: activating ALiS parser")
    save_parser(state.stream_id, "alis")
    handle_in(message, %{state | parser: Parser.get(:alis)})
  end

  def handle_in({_, [opcode: :binary]} = message, %{parser: nil} = state) do
    Logger.info("producer/#{state.stream_id}: activating raw text parser")
    save_parser(state.stream_id, "raw")
    handle_in(message, %{state | parser: Parser.get(:raw)})
  end

  def handle_in({_, [opcode: :text]} = message, %{parser: nil} = state) do
    Logger.info("producer/#{state.stream_id}: activating json parser")
    save_parser(state.stream_id, "json")
    handle_in(message, %{state | parser: Parser.get(:json)})
  end

  def handle_in({payload, _} = message, %{parser: parser} = state) do
    with {:ok, commands, new_parser_state} <- run_parser(parser, message),
         {:ok, state} <- run_commands(commands, state),
         {:ok, state} <- drain_bucket(state, byte_size(payload)) do
      {:ok, put_in(state, [:parser, :state], new_parser_state)}
    else
      {:error, :not_a_leader} ->
        Logger.info("producer/#{state.stream_id}: stream taken over by another producer")

        {:stop, :normal, state}

      {:error, {:invalid_vt_size, {cols, rows}}} ->
        Logger.info("producer/#{state.stream_id}: invalid vt size: #{cols}x#{rows}")

        {:stop, :normal, state}

      {:error, :bucket_empty} ->
        Logger.info("producer/#{state.stream_id}: byte budget exceeded")

        # TODO use reason other than :normal to make producer reconnect
        {:stop, :normal, state}

      {:error, {:parser, reason}} ->
        Logger.debug("producer/#{state.stream_id}: message: #{inspect(payload)}")
        Logger.warn("producer/#{state.stream_id}: parser error: #{reason}")

        {:stop, :normal, state}
    end
  end

  defp run_parser(%{impl: impl, state: state}, message) do
    with {:error, reason} <- impl.parse(message, state) do
      {:error, {:parser, reason}}
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

  defp run_command({:reset, %{size: {cols, rows}, init: init, time: time, theme: theme}}, state)
       when cols > 0 and rows > 0 and cols <= @max_cols and rows <= @max_rows do
    Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")

    state = ensure_server(state)

    with :ok <- LiveStreamServer.reset(state.stream_id, {cols, rows}, init, time, theme) do
      {:ok, state}
    end
  end

  defp run_command({:reset, %{size: size}}, _state) do
    {:error, {:invalid_vt_size, size}}
  end

  defp run_command({:feed, {time, data}}, %{status: :online} = state) do
    with :ok <- LiveStreamServer.feed(state.stream_id, {time, data}) do
      {:ok, state}
    end
  end

  defp run_command({:resize, {time, {cols, rows}}}, state)
       when cols > 0 and rows > 0 and cols <= @max_cols and rows <= @max_rows do
    with :ok <- LiveStreamServer.feed(state.stream_id, {time, resize_seq(cols, rows)}) do
      {:ok, state}
    end
  end

  defp run_command({:resize, size}, _state) do
    {:error, {:invalid_vt_size, size}}
  end

  defp run_command({:status, :offline}, %{status: :new} = state) do
    {:ok, state}
  end

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
    Process.send_after(self(), :heartbeat, @heartbeat_interval)

    %{state | status: :online}
  end

  @impl true
  def handle_info(:ping, state) do
    Process.send_after(self(), :ping, @ping_interval)

    {:push, {:ping, ""}, state}
  end

  def handle_info(:heartbeat, state) do
    Process.send_after(self(), :heartbeat, @heartbeat_interval)

    send_heartbeat(state)
  end

  def handle_info(:parser_check, %{parser: nil} = state) do
    Logger.info("producer/#{state.stream_id}: initial message timeout")

    {:stop, :parser_timeout, state}
  end

  def handle_info(:parser_check, state), do: {:ok, state}

  def handle_info(:fill_bucket, %{bucket: bucket} = state) do
    tokens = min(bucket.size, bucket.tokens + bucket.fill_amount)

    if tokens > bucket.tokens && tokens < bucket.size do
      Logger.debug("producer/#{state.stream_id}: fill to #{tokens}")
    end

    Process.send_after(self(), :fill_bucket, bucket.fill_interval)

    {:ok, put_in(state, [:bucket, :tokens], tokens)}
  end

  defp send_heartbeat(%{status: :online} = state) do
    case LiveStreamServer.heartbeat(state.stream_id) do
      :ok ->
        {:ok, state}

      {:error, :not_a_leader} ->
        Logger.info("producer/#{state.stream_id}: stream taken over by another producer")

        {:stop, :normal, state}
    end
  end

  defp send_heartbeat(state), do: {:ok, state}

  @impl true
  def terminate(reason, state) do
    Logger.info("producer/#{state.stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("producer/#{state.stream_id}: state: #{inspect(state)}")

    if reason == :remote do
      LiveStreamServer.stop(state.stream_id)
    end

    :ok
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

  defp resize_seq(cols, rows), do: "\x1b[8;#{rows};#{cols}t"

  defp config(key, default) do
    Application.get_env(:asciinema, :"live_stream_producer_#{key}", default)
  end
end
