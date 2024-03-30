defmodule AsciinemaWeb.LiveStreamConsumerSocket do
  alias Asciinema.Streaming
  alias Asciinema.Streaming.{LiveStreamServer, ViewerTracker}
  require Logger

  @behaviour Phoenix.Socket.Transport

  @info_timeout 1_000
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
    Logger.info("consumer/#{id}: connected")

    {:ok, %{stream_id: id}}
  end

  @impl true
  def init(state) do
    state =
      case Streaming.get_live_stream(state.stream_id) do
        nil ->
          Logger.warn("consumer: stream not found for ID #{state.stream_id}")
          send(self(), :not_found)

          state

        live_stream ->
          send(self(), :push_alis_header)
          LiveStreamServer.subscribe(live_stream.id, :stream)
          LiveStreamServer.subscribe(live_stream.id, :status)
          LiveStreamServer.request_info(live_stream.id)
          ViewerTracker.track(live_stream.id)
          Process.send_after(self(), :info_timeout, @info_timeout)
          Process.send_after(self(), :ping, @ping_interval)

          %{stream_id: live_stream.id, reset: false}
      end

    {:ok, state}
  end

  @impl true
  def handle_in({_text, _opts}, state) do
    {:ok, state}
  end

  @impl true
  def handle_info(:not_found, state) do
    {:stop, :not_found, state}
  end

  def handle_info(:push_alis_header, state) do
    Logger.debug("consumer/#{state.stream_id}: sending alis header")

    {:push, header_message(), state}
  end

  def handle_info(%LiveStreamServer.Update{event: e, data: data}, state)
      when e in [:info, :reset] do
    {{cols, rows}, _, _, _} = data
    Logger.info("consumer/#{state.stream_id}: reset (#{cols}x#{rows})")

    {:push, reset_message(data), %{state | reset: true}}
  end

  def handle_info(%LiveStreamServer.Update{event: :feed, data: data}, %{reset: true} = state) do
    {:push, feed_message(data), state}
  end

  def handle_info(%LiveStreamServer.Update{}, %{reset: false} = state) do
    {:ok, state}
  end

  def handle_info(%LiveStreamServer.Update{event: :status, data: :offline}, state) do
    {:push, offline_message(), state}
  end

  def handle_info(%LiveStreamServer.Update{event: :status, data: :online}, state) do
    {:ok, state}
  end

  def handle_info(:ping, state) do
    Process.send_after(self(), :ping, @ping_interval)

    {:push, {:ping, ""}, state}
  end

  def handle_info(:info_timeout, %{reset: false} = state) do
    {:push, offline_message(), state}
  end

  def handle_info(:info_timeout, %{reset: true} = state), do: {:ok, state}

  @impl true
  def terminate(reason, state) do
    Logger.info("consumer/#{state.stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("consumer/#{state.stream_id}: state: #{inspect(state)}")
    ViewerTracker.untrack(state.stream_id)

    :ok
  end

  # Private

  @alis_version 1

  @msg_type_reset 0x01
  @msg_type_output ?o
  @msg_type_offline 0x04

  defp header_message do
    msg = <<"ALiS"::binary, @alis_version::unsigned-8>>

    {:binary, msg}
  end

  defp reset_message({{cols, rows}, init, time, nil}) do
    theme_absent = 0
    init = init || ""
    init_len = byte_size(init)

    msg = <<
      @msg_type_reset::8,
      cols::little-16,
      rows::little-16,
      time::little-float-32,
      theme_absent::8,
      init_len::little-32,
      init::binary
    >>

    {:binary, msg}
  end

  defp reset_message({{cols, rows}, init, time, theme}) do
    theme_present = 1
    init = init || ""
    init_len = byte_size(init)

    msg = <<
      @msg_type_reset::8,
      cols::little-16,
      rows::little-16,
      time::little-float-32,
      theme_present::8,
      theme::binary-size(18 * 3),
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
