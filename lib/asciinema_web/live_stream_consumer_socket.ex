defmodule AsciinemaWeb.LiveStreamConsumerSocket do
  alias Asciinema.Streaming
  alias Asciinema.Streaming.{LiveStreamServer, ViewerTracker}
  require Logger

  @behaviour :cowboy_websocket

  @info_timeout 1_000
  @client_ping_interval 15_000

  # Callbacks

  @impl true
  def init(req, _opts),
    do: {:cowboy_websocket, req, req.bindings[:public_token], %{compress: true}}

  @impl true
  def websocket_init(token) do
    case Streaming.get_live_stream(token) do
      nil ->
        Logger.warn("consumer: stream not found for public token #{token}")
        :timer.sleep(1000)

        {:reply, :close, %{stream_id: "?"}}

      stream ->
        Logger.info("consumer/#{stream.id}: connected")
        state = %{stream_id: stream.id, reset: false}
        LiveStreamServer.subscribe(stream.id, :reset)
        LiveStreamServer.subscribe(stream.id, :feed)
        LiveStreamServer.subscribe(stream.id, :offline)
        LiveStreamServer.request_info(stream.id)
        ViewerTracker.track(stream.id)
        Process.send_after(self(), :info_timeout, @info_timeout)
        Process.send_after(self(), :client_ping, @client_ping_interval)

        {:reply, header_message(), state}
    end
  end

  @impl true
  def websocket_handle(_frame, state), do: {:ok, state}

  @impl true
  def websocket_info(message, state)

  def websocket_info(%LiveStreamServer.Update{event: e, data: data}, state)
      when e in [:info, :reset] do
    {{cols, rows}, _, _, _} = data
    Logger.info("consumer/#{state.stream_id}: reset (#{cols}x#{rows})")

    {:reply, reset_message(data), %{state | reset: true}}
  end

  def websocket_info(%LiveStreamServer.Update{event: :feed, data: data}, %{reset: true} = state) do
    {:reply, feed_message(data), state}
  end

  def websocket_info(%LiveStreamServer.Update{}, %{reset: false} = state) do
    {:ok, state}
  end

  def websocket_info(%LiveStreamServer.Update{event: :offline}, state) do
    {:reply, offline_message(), state}
  end

  def websocket_info(:client_ping, state) do
    Process.send_after(self(), :client_ping, @client_ping_interval)

    {:reply, :ping, state}
  end

  def websocket_info(:info_timeout, %{reset: false} = state) do
    {:reply, offline_message(), state}
  end

  def websocket_info(:info_timeout, %{reset: true} = state), do: {:ok, state}

  @impl true
  def terminate(reason, _req, state) do
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
