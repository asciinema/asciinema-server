defmodule AsciinemaWeb.LiveStreamProducerSocket do
  alias Asciinema.LiveStream
  alias Asciinema.LiveStreamSupervisor
  require Logger

  @behaviour Phoenix.Socket.Transport

  @ping_interval 15_000
  @heartbeat_interval 15_000
  @reset_timeout 5_000

  # Callbacks

  @impl true
  def child_spec(_opts) do
    # We won't spawn any process, so let's return a dummy task
    %{id: __MODULE__, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  @impl true
  def connect(state) do
    {:ok, %{stream_id: state.params["id"], init: false}}
  end

  @impl true
  def init(state) do
    Logger.info("producer/#{state.stream_id}: connected")
    {:ok, _pid} = LiveStreamSupervisor.ensure_child(state.stream_id)
    :ok = LiveStream.lead(state.stream_id)
    Process.send_after(self(), :reset_timeout, @reset_timeout)
    Process.send_after(self(), :ping, @ping_interval)
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
         {:ok, state} <- handle_message(message, state) do
      {:ok, state}
    else
      {:error, _} ->
        {:stop, :normal, state}
    end
  end

  def handle_message(%{"cols" => cols, "rows" => rows} = header, state)
      when is_integer(cols) and is_integer(rows) and cols > 0 and rows > 0 and cols <= @max_cols and
             rows <= @max_rows do
    Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")

    with :ok <- LiveStream.reset(state.stream_id, {cols, rows}, header["init"], header["time"]) do
      {:ok, %{state | init: true}}
    end
  end

  def handle_message(%{"width" => cols, "height" => rows}, state)
      when is_integer(cols) and is_integer(rows) and cols > 0 and rows > 0 and cols <= @max_cols and
             rows <= @max_rows do
    Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")

    with :ok <- LiveStream.reset(state.stream_id, {cols, rows}) do
      {:ok, %{state | init: true}}
    end
  end

  def handle_message(header, state) when is_map(header) do
    Logger.info("producer/#{state.stream_id}: invalid header: #{inspect(header)}")

    {:error, :invalid_message}
  end

  def handle_message([time, "o", data], %{init: true} = state)
      when is_number(time) and is_binary(data) do
    with :ok <- LiveStream.feed(state.stream_id, {time, data}) do
      {:ok, state}
    end
  end

  def handle_message([time, type, data], %{init: true} = state)
      when is_number(time) and is_binary(type) and is_binary(data) do
    {:ok, state}
  end

  def handle_message([time, type, data], %{init: false} = state)
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
        Logger.info("producer/#{state.stream_id}: stream taken by another producer")

        {:stop, :normal, state}
    end
  end

  def handle_info(:reset_timeout, %{init: false} = state) do
    Logger.info("producer/#{state.stream_id}: initial reset timeout")

    {:stop, :reset_timeout, state}
  end

  def handle_info(:reset_timeout, %{init: true} = state), do: {:ok, state}

  @impl true
  def terminate(reason, state) do
    Logger.info(
      "producer/#{state.stream_id}: terminating | reason: #{inspect(reason)}, state: #{inspect(state)}"
    )

    :ok
  end
end
