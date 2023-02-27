defmodule AsciinemaWeb.LiveStreamConsumerSocket do
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
    {:ok, {vt_size, vt_state, stream_time}} = LiveStream.join(state.stream_id)
    send(self(), {:push, reset_message(vt_size)})
    send(self(), {:push, feed_message({stream_time, vt_state})})
    schedule_ping()

    {:ok, state}
  end

  @impl true
  def handle_in({_text, _opts}, state) do
    {:ok, state}
  end

  @impl true
  def handle_info({:push, message}, state) do
    {:push, message, state}
  end

  def handle_info({:live_stream, {:reset, vt_size}}, state) do
    {:push, reset_message(vt_size), state}
  end

  def handle_info({:live_stream, {:feed, event}}, state) do
    {:push, feed_message(event), state}
  end

  def handle_info(:ping, state) do
    schedule_ping()

    {:push, {:ping, ""}, state}
  end

  @impl true
  def terminate(_reason, state) do
    Logger.debug("consumer: state on termination: #{inspect(state)}")

    :ok
  end

  # Private

  defp reset_message({cols, rows}) do
    {:text, Jason.encode!(%{cols: cols, rows: rows})}
  end

  defp feed_message({time, data}) do
    {:text, Jason.encode!([time, "o", data])}
    # {:binary, data}
  end

  @ping_interval 15_000

  defp schedule_ping do
    Process.send_after(self(), :ping, @ping_interval)
  end
end
