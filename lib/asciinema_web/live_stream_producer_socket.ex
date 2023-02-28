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
    {:ok, _pid} = LiveStreamSupervisor.ensure_child(state.stream_id)
    schedule_ping()

    {:ok, state}
  end

  @impl true
  def handle_in({text, _opts}, state) do
    case Jason.decode(text) do
      {:ok, %{"cols" => cols, "rows" => rows}} ->
        Logger.debug("producer: reset (#{cols}x#{rows})")
        :ok = LiveStream.reset(state.stream_id, {cols, rows})

      {:ok, %{"width" => cols, "height" => rows}} ->
        Logger.debug("producer: reset (#{cols}x#{rows})")
        :ok = LiveStream.reset(state.stream_id, {cols, rows})

      {:ok, header} when is_map(header) ->
        Logger.debug("producer: invalid header: #{inspect(header)}")

      {:ok, [time, "o", data]} ->
        :ok = LiveStream.feed(state.stream_id, {time, data})

      {:ok, [_, _, _]} ->
        :ok

      _otherwise ->
        Logger.debug("producer: invalid message: #{inspect(text)}")
    end

    {:ok, state}
  end

  @impl true
  def handle_info(:ping, state) do
    schedule_ping()

    {:push, {:ping, ""}, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  @impl true
  def terminate(_reason, state) do
    Logger.debug("producer: state on termination: #{inspect(state)}")

    :ok
  end

  # Private

  @ping_interval 15_000

  defp schedule_ping do
    Process.send_after(self(), :ping, @ping_interval)
  end
end
