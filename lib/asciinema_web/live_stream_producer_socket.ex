defmodule AsciinemaWeb.LiveStreamProducerSocket do
  alias Asciinema.LiveStream
  alias Asciinema.LiveStreamSupervisor
  require Logger

  @behaviour Phoenix.Socket.Transport

  @reset_timeout 5_000
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
      reset: false,
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
    :ok = LiveStream.lead(state.stream_id)
    Process.send_after(self(), :reset_timeout, @reset_timeout)
    Process.send_after(self(), :ping, @ping_interval)
    Process.send_after(self(), :fill_bucket, state.bucket.fill_interval)
    send(self(), :heartbeat)

    {:ok, state}
  end

  @impl true
  def handle_in({"\n", _opts}, state) do
    {:ok, state}
  end

  @max_cols 720
  @max_rows 200

  def handle_in({text, [opcode: :text]}, state) do
    with {:ok, message} <- Jason.decode(text),
         {:ok, state} <- handle_message(message, state),
         {:ok, state} <- drain_bucket(state, byte_size(text)) do
      {:ok, state}
    else
      {:error, :not_a_leader} ->
        Logger.info("producer/#{state.stream_id}: stream taken over by another producer")

        {:stop, :normal, state}

      {:error, :bucket_empty} ->
        Logger.info("producer/#{state.stream_id}: byte budget exceeded")

        # TODO use reason other than :normal to make streamer reconnect
        {:stop, :normal, state}

      {:error, _} ->
        {:stop, :normal, state}
    end
  end

  def handle_in(_, state) do
    Logger.info("producer/#{state.stream_id}: binary message received, disconnecting")

    {:stop, :normal, state}
  end

  def handle_message(%{"cols" => cols, "rows" => rows} = header, state)
      when is_integer(cols) and is_integer(rows) and cols > 0 and rows > 0 and cols <= @max_cols and
             rows <= @max_rows do
    Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")

    with :ok <- LiveStream.reset(state.stream_id, {cols, rows}, header["init"], header["time"]) do
      {:ok, %{state | reset: true}}
    end
  end

  def handle_message(%{"width" => cols, "height" => rows}, state)
      when is_integer(cols) and is_integer(rows) and cols > 0 and rows > 0 and cols <= @max_cols and
             rows <= @max_rows do
    Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")

    with :ok <- LiveStream.reset(state.stream_id, {cols, rows}) do
      {:ok, %{state | reset: true}}
    end
  end

  def handle_message(header, state) when is_map(header) do
    Logger.info("producer/#{state.stream_id}: invalid header: #{inspect(header)}")

    {:error, :invalid_message}
  end

  def handle_message([time, "o", data], %{reset: true} = state)
      when is_number(time) and is_binary(data) do
    with :ok <- LiveStream.feed(state.stream_id, {time, data}) do
      {:ok, state}
    end
  end

  def handle_message([time, type, data], %{reset: true} = state)
      when is_number(time) and is_binary(type) and is_binary(data) do
    {:ok, state}
  end

  def handle_message([time, type, data], %{reset: false} = state)
      when is_number(time) and is_binary(type) and is_binary(data) do
    Logger.info("producer/#{state.stream_id}: expected header, got event")

    {:error, :unexpected_message}
  end

  def handle_message(message, state) do
    Logger.info("producer/#{state.stream_id}: invalid message: #{inspect(message)}")

    {:error, :invalid_message}
  end

  @impl true
  def handle_info(:ping, state) do
    Process.send_after(self(), :ping, @ping_interval)

    {:push, {:ping, ""}, state}
  end

  def handle_info(:heartbeat, state) do
    Process.send_after(self(), :heartbeat, @heartbeat_interval)

    case LiveStream.heartbeat(state.stream_id) do
      :ok ->
        {:ok, state}

      {:error, :not_a_leader} ->
        Logger.info("producer/#{state.stream_id}: stream taken over by another producer")

        {:stop, :normal, state}
    end
  end

  def handle_info(:reset_timeout, %{reset: false} = state) do
    Logger.info("producer/#{state.stream_id}: initial reset timeout")

    {:stop, :reset_timeout, state}
  end

  def handle_info(:reset_timeout, %{reset: true} = state), do: {:ok, state}

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
