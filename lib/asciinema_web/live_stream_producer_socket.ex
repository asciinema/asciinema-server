defmodule AsciinemaWeb.LiveStreamProducerSocket do
  alias Asciinema.LiveStream
  alias Asciinema.LiveStreamSupervisor
  require Logger

  @behaviour Phoenix.Socket.Transport

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
    schedule_ping()

    {:ok, state}
  end

  @impl true
  def handle_in({"\n", _opts}, state) do
    {:ok, state}
  end

  def handle_in({text, _opts}, state) do
    result =
      case Jason.decode(text) do
        # TODO add guard for positive cols/rows
        {:ok, %{"cols" => cols, "rows" => rows}} when is_integer(cols) and is_integer(rows) ->
          Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")
          LiveStream.reset(state.stream_id, {cols, rows})

        # TODO add guard for positive cols/rows
        {:ok, %{"width" => cols, "height" => rows}} when is_integer(cols) and is_integer(rows) ->
          Logger.info("producer/#{state.stream_id}: reset (#{cols}x#{rows})")
          LiveStream.reset(state.stream_id, {cols, rows})

        {:ok, header} when is_map(header) ->
          Logger.debug("producer/#{state.stream_id}: invalid header: #{inspect(header)}")
          :ok

        {:ok, [time, "o", data]} when is_number(time) and is_binary(data) ->
          LiveStream.feed(state.stream_id, {time, data})

        {:ok, [time, _, data]} when is_number(time) and is_binary(data) ->
          :ok

        {:error, reason} = error ->
          Logger.debug("producer/#{state.stream_id}: invalid message: #{inspect(reason)}")
          error

        _otherwise ->
          Logger.debug("producer/#{state.stream_id}: invalid message: #{inspect(text)}")
          :ok
      end

    case result do
      :ok ->
        {:ok, state}

      {:error, :not_a_leader} ->
        {:stop, :normal, state}

      {:error, %Jason.DecodeError{}} ->
        {:stop, :normal, state}
    end
  end

  @impl true
  def handle_info(:ping, state) do
    schedule_ping()

    case LiveStream.heartbeat(state.stream_id) do
      :ok ->
        {:push, {:ping, ""}, state}

      {:error, :not_a_leader} ->
        {:stop, :normal, state}
    end
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  @impl true
  def terminate(_reason, state) do
    Logger.info("producer/#{state.stream_id}: terminating, state: #{inspect(state)}")

    :ok
  end

  # Private

  @ping_interval 15_000

  defp schedule_ping do
    Process.send_after(self(), :ping, @ping_interval)
  end
end
