defmodule AsciinemaWeb.LiveStreamConsumerSocket do
  alias Asciinema.LiveStream
  require Logger

  @behaviour Phoenix.Socket.Transport

  @reset_timeout 1_000
  @ping_interval 15_000

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
    Logger.info("consumer/#{state.stream_id}: connected")
    LiveStream.join(state.stream_id)
    Process.send_after(self(), :reset_timeout, @reset_timeout)
    Process.send_after(self(), :ping, @ping_interval)

    {:ok, state}
  end

  @impl true
  def handle_in({_text, _opts}, state) do
    {:ok, state}
  end

  @impl true
  def handle_info({:live_stream, {:reset, {{_, _}, _, _} = data}}, state) do
    Logger.info("consumer/#{state.stream_id}: reset")

    {:push, reset_message(data), %{state | init: true}}
  end

  def handle_info({:live_stream, {:feed, event}}, %{init: true} = state) do
    {:push, feed_message(event), state}
  end

  def handle_info({:live_stream, :offline}, state) do
    {:push, offline_message(), state}
  end

  def handle_info({:live_stream, _}, %{init: false} = state) do
    {:ok, state}
  end

  def handle_info(:ping, state) do
    Process.send_after(self(), :ping, @ping_interval)

    {:push, {:ping, ""}, state}
  end

  def handle_info(:reset_timeout, %{init: false} = state) do
    {:push, offline_message(), state}
  end

  def handle_info(:reset_timeout, %{init: true} = state), do: {:ok, state}

  @impl true
  def terminate(reason, state) do
    Logger.info(
      "consumer/#{state.stream_id}: terminating | reason: #{inspect(reason)}, state: #{inspect(state)}"
    )

    :ok
  end

  # Private

  defp reset_message({{cols, rows}, vt_init, stream_time}) do
    {:text, Jason.encode!(%{cols: cols, rows: rows, init: vt_init, time: stream_time})}
  end

  defp feed_message({time, data}) do
    {:text, Jason.encode!([time, "o", data])}
  end

  defp offline_message do
    {:text, Jason.encode!(%{state: "offline"})}
  end
end
