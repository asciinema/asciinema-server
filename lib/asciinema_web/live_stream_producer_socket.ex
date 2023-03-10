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
    {:ok, %{stream_id: state.params["id"], reset_timeout_timer: nil}}
  end

  @impl true
  def init(state) do
    Logger.info("producer/#{state.stream_id}: connected")
    {:ok, _pid} = LiveStreamSupervisor.ensure_child(state.stream_id)
    :ok = LiveStream.lead(state.stream_id)
    reset_timeout_timer = Process.send_after(self(), :reset_timeout, @reset_timeout)
    Process.send_after(self(), :ping, @ping_interval)
    send(self(), :heartbeat)

    {:ok, %{state | reset_timeout_timer: reset_timeout_timer}}
  end

  @impl true
  def handle_in({"\n", _opts}, state) do
    {:ok, state}
  end

  @max_cols 720
  @max_rows 200

  def handle_in({text, _opts}, state) do
    result =
      case Jason.decode(text) do
        {:ok, %{"cols" => cols, "rows" => rows} = header}
        when is_integer(cols) and is_integer(rows) and cols > 0 and rows > 0 and cols <= @max_cols and
               rows <= @max_rows ->
          Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")

          if state.reset_timeout_timer do
            Process.cancel_timer(state.reset_timeout_timer)
          end

          LiveStream.reset(state.stream_id, {cols, rows}, header["init"], header["time"])

        {:ok, %{"width" => cols, "height" => rows}}
        when is_integer(cols) and is_integer(rows) and cols > 0 and rows > 0 and cols <= @max_cols and
               rows <= @max_rows ->
          Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")

          if state.reset_timeout_timer do
            Process.cancel_timer(state.reset_timeout_timer)
          end

          LiveStream.reset(state.stream_id, {cols, rows})

        {:ok, header} when is_map(header) ->
          Logger.info("producer/#{state.stream_id}: invalid header: #{inspect(header)}")
          :error

        {:ok, [time, "o", data]} when is_number(time) and is_binary(data) ->
          LiveStream.feed(state.stream_id, {time, data})

        {:ok, [time, _, data]} when is_number(time) and is_binary(data) ->
          :ok

        result ->
          Logger.info("producer/#{state.stream_id}: invalid message: #{inspect(result)}")
          :error
      end

    case result do
      :ok ->
        {:ok, state}

      :error ->
        {:stop, :normal, state}
    end
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

  def handle_info(:reset_timeout, state) do
    Logger.info("producer/#{state.stream_id}: initial reset timeout")

    {:stop, :reset_timeout, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info(
      "producer/#{state.stream_id}: terminating | reason: #{inspect(reason)}, state: #{inspect(state)}"
    )

    :ok
  end
end
