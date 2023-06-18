defmodule AsciinemaWeb.LiveStreamProducerSocket do
  alias Asciinema.Streaming
  alias Asciinema.Streaming.{LiveStreamServer, LiveStreamSupervisor, ProducerHandler}
  require Logger

  @behaviour Phoenix.Socket.Transport

  @handler_timeout 5_000
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
    state = %{
      stream_id: state.params["id"],
      handler: nil,
      bucket: %{
        size: config(:bucket_size, @default_bucket_size),
        tokens: config(:bucket_size, @default_bucket_size),
        fill_interval: config(:bucket_fill_interval, @default_bucket_fill_interval),
        fill_amount: config(:bucket_fill_amount, @default_bucket_fill_amount)
      }
    }

    {:ok, state}
  end

  @impl true
  def init(state) do
    Logger.info("producer/#{state.stream_id}: connected")
    {:ok, _pid} = LiveStreamSupervisor.ensure_child(state.stream_id)
    :ok = LiveStreamServer.lead(state.stream_id)
    Process.send_after(self(), :handler_timeout, @handler_timeout)
    Process.send_after(self(), :ping, @ping_interval)
    Process.send_after(self(), :fill_bucket, state.bucket.fill_interval)
    send(self(), :heartbeat)

    {:ok, state}
  end

  @impl true
  def handle_in({_, [opcode: :binary]} = message, %{handler: nil} = state) do
    handle_in(message, %{state | handler: ProducerHandler.get(:raw)})
  end

  def handle_in({_, [opcode: :text]} = message, %{handler: nil} = state) do
    handle_in(message, %{state | handler: ProducerHandler.get(:json)})
  end

  def handle_in({payload, _} = message, %{handler: handler} = state) do
    with {:ok, commands, new_handler_state} <- run_handler(handler, message),
         :ok <- run_commands(commands, state.stream_id),
         {:ok, state} <- drain_bucket(state, byte_size(payload)) do
      {:ok, put_in(state, [:handler, :state], new_handler_state)}
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

      {:error, {:handler, reason}} ->
        Logger.debug("producer/#{state.stream_id}: message: #{inspect(payload)}")
        Logger.warn("producer/#{state.stream_id}: handler error: #{reason}")

        {:stop, :normal, state}
    end
  end

  defp run_handler(%{impl: impl, state: state}, message) do
    with {:error, reason} <- impl.parse(message, state) do
      {:error, {:handler, reason}}
    end
  end

  defp run_commands(commands, stream_id) do
    Enum.reduce(commands, :ok, fn command, prev_result ->
      with :ok <- prev_result do
        run_command(command, stream_id)
      end
    end)
  end

  @max_cols 720
  @max_rows 200

  defp run_command({:reset, %{size: {cols, rows}, init: init, time: time}}, stream_id)
       when cols > 0 and rows > 0 and cols <= @max_cols and rows <= @max_rows do
    Logger.info("producer/#{stream_id}: reset (#{cols}x#{rows})")

    LiveStreamServer.reset(stream_id, {cols, rows}, init, time)
  end

  defp run_command({:reset, %{size: {cols, rows}}}, _stream_id) do
    {:error, {:invalid_vt_size, {cols, rows}}}
  end

  defp run_command({:feed, {time, data}}, stream_id) do
    LiveStreamServer.feed(stream_id, {time, data})
  end

  @impl true
  def handle_info(:ping, state) do
    Process.send_after(self(), :ping, @ping_interval)

    {:push, {:ping, ""}, state}
  end

  def handle_info(:heartbeat, state) do
    Process.send_after(self(), :heartbeat, @heartbeat_interval)

    case LiveStreamServer.heartbeat(state.stream_id) do
      :ok ->
        {:ok, state}

      {:error, :not_a_leader} ->
        Logger.info("producer/#{state.stream_id}: stream taken over by another producer")

        {:stop, :normal, state}
    end
  end

  def handle_info(:handler_timeout, %{handler: nil} = state) do
    Logger.info("producer/#{state.stream_id}: handler init timeout")

    {:stop, :handler_timeout, state}
  end

  def handle_info(:handler_timeout, state), do: {:ok, state}

  def handle_info(:fill_bucket, %{bucket: bucket} = state) do
    tokens = min(bucket.size, bucket.tokens + bucket.fill_amount)

    if tokens > bucket.tokens && tokens < bucket.size do
      Logger.debug("producer/#{state.stream_id}: fill to #{tokens}")
    end

    Process.send_after(self(), :fill_bucket, bucket.fill_interval)

    {:ok, put_in(state, [:bucket, :tokens], tokens)}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info(
      "producer/#{state.stream_id}: terminating | reason: #{inspect(reason)}, state: #{inspect(state)}"
    )

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

  defp config(key, default) do
    Application.get_env(:asciinema, :"live_stream_producer_#{key}", default)
  end
end
