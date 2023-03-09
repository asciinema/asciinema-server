defmodule AsciinemaWeb.LiveStreamProducerSocket do
  alias Asciinema.LiveStream
  alias Asciinema.LiveStreamSupervisor
  require Logger

  @behaviour Phoenix.Socket.Transport

  @ping_interval 15_000
  @heartbeat_interval 15_000

  # Callbacks

  @impl true
  def child_spec(_opts) do
    # We won't spawn any process, so let's return a dummy task
    %{id: __MODULE__, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  @impl true
  def connect(state) do
    {:ok, %{stream_id: state.params["id"]}}
  end

  @impl true
  def init(state) do
    Logger.info("producer/#{state.stream_id}: connected")
    {:ok, _pid} = LiveStreamSupervisor.ensure_child(state.stream_id)
    :ok = LiveStream.lead(state.stream_id)
    send(self(), :heartbeat)
    Process.send_after(self(), :ping, @ping_interval)

    {:ok, state}
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
        {:ok, %{"cols" => cols, "rows" => rows}}
        when is_integer(cols) and is_integer(rows) and cols > 0 and rows > 0 and cols <= @max_cols and
               rows <= @max_rows ->
          Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")
          LiveStream.reset(state.stream_id, {cols, rows})

        {:ok, %{"width" => cols, "height" => rows}}
        when is_integer(cols) and is_integer(rows) and cols > 0 and rows > 0 and cols <= @max_cols and
               rows <= @max_rows ->
          Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")
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
        {:stop, :normal, state}
    end
  end

  @impl true
  def terminate(reason, state) do
    Logger.info(
      "producer/#{state.stream_id}: terminating | reason: #{inspect(reason)}, state: #{inspect(state)}"
    )

    :ok
  end
end
