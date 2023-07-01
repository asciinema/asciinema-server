defmodule AsciinemaWeb.LiveStreamConsumerSocket do
  alias Asciinema.Streaming
  alias Asciinema.Streaming.LiveStreamServer
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
    id = state.params["id"]

    case Streaming.get_live_stream(id) do
      nil ->
        Logger.warn("consumer: stream not found for ID #{id}")

        :error

      live_stream ->
        {:ok, %{stream_id: live_stream.id, reset: false}}
    end
  end

  @impl true
  def init(state) do
    Logger.info("consumer/#{state.stream_id}: connected")
    LiveStreamServer.join(state.stream_id)
    Process.send_after(self(), :reset_timeout, @reset_timeout)
    Process.send_after(self(), :ping, @ping_interval)
    send(self(), :push_alis_header)

    {:ok, state}
  end

  @impl true
  def handle_in({_text, _opts}, state) do
    {:ok, state}
  end

  @impl true
  def handle_info(:push_alis_header, state) do
    Logger.debug("consumer/#{state.stream_id}: sending alis header")

    {:push, header_message(), state}
  end

  def handle_info({:live_stream, {:reset, {{cols, rows}, _, _} = data}}, state) do
    Logger.info("consumer/#{state.stream_id}: reset (#{cols}x#{rows})")

    {:push, reset_message(data), %{state | reset: true}}
  end

  def handle_info({:live_stream, {:feed, event}}, %{reset: true} = state) do
    {:push, feed_message(event), state}
  end

  def handle_info({:live_stream, :offline}, state) do
    {:push, offline_message(), state}
  end

  def handle_info({:live_stream, _}, %{reset: false} = state) do
    {:ok, state}
  end

  def handle_info(:ping, state) do
    Process.send_after(self(), :ping, @ping_interval)

    {:push, {:ping, ""}, state}
  end

  def handle_info(:reset_timeout, %{reset: false} = state) do
    {:push, offline_message(), state}
  end

  def handle_info(:reset_timeout, %{reset: true} = state), do: {:ok, state}

  @impl true
  def terminate(reason, state) do
    Logger.info("consumer/#{state.stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("consumer/#{state.stream_id}: state: #{inspect(state)}")

    :ok
  end

  # Private

  @alis_version 1
  @compression_algo_none 0

  @msg_type_reset 0x01
  @msg_type_output ?o
  @msg_type_offline 0x04

  defp header_message do
    msg = <<
      "ALiS"::binary,
      @alis_version::unsigned-8,
      @compression_algo_none::unsigned-8,
      0x00,
      0x00,
      0x00,
      0x00
    >>

    {:binary, msg}
  end

  defp reset_message({{cols, rows}, init, time}) do
    init = init || ""
    init_len = byte_size(init)

    msg = <<
      @msg_type_reset,
      cols::little-16,
      rows::little-16,
      time::little-float-32,
      init_len::little-32,
      init::binary
    >>

    {:binary, msg}
  end

  defp feed_message({time, data}) do
    data_len = byte_size(data)

    msg = <<
      @msg_type_output,
      time::little-float-32,
      data_len::little-32,
      data::binary
    >>

    {:binary, msg}
  end

  defp offline_message do
    {:binary, <<@msg_type_offline>>}
  end
end
