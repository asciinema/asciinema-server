defmodule AsciinemaWeb.LiveStreamProducerSocket do
  alias Asciinema.LiveStream
  alias Asciinema.LiveStreamSupervisor
  require Logger

  @behaviour Phoenix.Socket.Transport

  @reset_timeout 5_000
  @ping_interval 15_000
  @heartbeat_interval 15_000
  @bucket_fill_interval 100
  @bucket_fill_amount 10_000
  @bucket_size 60_000_000

  # Callbacks

  @impl true
  def child_spec(_opts) do
    # We won't spawn any process, so let's return a dummy task
    %{id: __MODULE__, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  @impl true
  def connect(state) do
    {:ok, %{stream_id: state.params["id"], reset: false, bucket: @bucket_size}}
  end

  @impl true
  def init(state) do
    Logger.info("producer/#{state.stream_id}: connected")
    {:ok, _pid} = LiveStreamSupervisor.ensure_child(state.stream_id)
    :ok = LiveStream.lead(state.stream_id)
    Process.send_after(self(), :reset_timeout, @reset_timeout)
    Process.send_after(self(), :ping, @ping_interval)
    Process.send_after(self(), :fill_bucket, @bucket_fill_interval)
    send(self(), :heartbeat)

    {:ok, state}
  end

  @impl true
  def handle_in({"\n", _opts}, state) do
    {:ok, state}
  end

  @max_cols 720
  @max_rows 200

  def handle_in({text, _opts}, state) do
    with {:ok, message} <- Jason.decode(text),
         {:ok, state} <- handle_message(message, state),
         {:ok, state} <- drain_bucket(state, byte_size(text)) do
      {:ok, state}
    else
      {:error, :not_a_leader} ->
        Logger.info("producer/#{state.stream_id}: stream taken over by another producer")

        {:stop, :normal, state}

      {:error, :empty_bucket} ->
        Logger.info("producer/#{state.stream_id}: byte budget exceeded")

        # TODO use reason other than :normal to make streamer reconnect
        {:stop, :normal, state}

      {:error, _} ->
        {:stop, :normal, state}
    end
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

  def handle_info(:fill_bucket, state) do
    bucket = min(@bucket_size, state.bucket + @bucket_fill_amount)

    if bucket > state.bucket && bucket < @bucket_size do
      Logger.debug("producer/#{state.stream_id}: fill to #{bucket}")
    end

    Process.send_after(self(), :fill_bucket, @bucket_fill_interval)

    {:ok, %{state | bucket: bucket}}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info(
      "producer/#{state.stream_id}: terminating | reason: #{inspect(reason)}, state: #{inspect(state)}"
    )

    :ok
  end

  defp drain_bucket(state, drain_amount) do
    bucket = state.bucket - drain_amount

    if bucket < 0 do
      {:error, :empty_bucket}
    else
      {:ok, %{state | bucket: bucket}}
    end
  end
end
