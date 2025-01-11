defmodule AsciinemaWeb.LiveStreamConsumerSocket do
  alias Asciinema.{Accounts, Authorization, Streaming}
  alias Asciinema.Streaming.{LiveStreamServer, ViewerTracker}
  alias AsciinemaWeb.Endpoint
  require Logger

  @behaviour :cowboy_websocket

  @info_timeout 1_000
  @client_ping_interval 15_000

  # Callbacks

  @impl true
  def init(req, _opts) do
    state = %{
      token: req.bindings[:public_token],
      user_id: user_id_from_session(req),
      stream_id: nil
    }

    {:cowboy_websocket, req, state, %{compress: true}}
  end

  @impl true
  def websocket_init(%{token: token, user_id: user_id}) do
    with {:ok, stream} <- fetch_live_stream(token),
         :ok <- authorize(stream, user_id) do
      Logger.info("consumer/#{stream.id}: connected")
      state = %{stream_id: stream.id, reset: false}
      LiveStreamServer.subscribe(stream.id, :reset)
      LiveStreamServer.subscribe(stream.id, :output)
      LiveStreamServer.subscribe(stream.id, :resize)
      LiveStreamServer.subscribe(stream.id, :offline)
      LiveStreamServer.request_info(stream.id)
      ViewerTracker.track(stream.id)
      Process.send_after(self(), :info_timeout, @info_timeout)
      Process.send_after(self(), :client_ping, @client_ping_interval)

      {:reply, header_message(), state}
    else
      {:error, :stream_not_found} ->
        Logger.warn("consumer: stream not found for public token #{token}")
        :timer.sleep(1000)

        {:reply, :close, %{stream_id: "?"}}

      {:error, :forbidden} ->
        Logger.warn("consumer: unauthorized connection attempt")

        {:reply, :close, %{stream_id: token}}
    end
  end

  @impl true
  def websocket_handle(_frame, state), do: {:ok, state}

  @impl true
  def websocket_info(message, state)

  def websocket_info(%LiveStreamServer.Update{event: e} = update, state)
      when e in [:info, :reset] do
    {{cols, rows}, _, _, _} = update.data
    Logger.debug("consumer/#{state.stream_id}: reset (#{cols}x#{rows})")

    {:reply, reset_message(update.data), %{state | reset: true}}
  end

  def websocket_info(%LiveStreamServer.Update{}, %{reset: false} = state) do
    {:ok, state}
  end

  def websocket_info(%LiveStreamServer.Update{event: :output} = update, state) do
    {:reply, output_message(update.data), state}
  end

  def websocket_info(%LiveStreamServer.Update{event: :resize} = update, state) do
    {:reply, resize_message(update.data), state}
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
    if stream_id = state[:stream_id] do
      Logger.info("consumer/#{stream_id}: terminating (#{inspect(reason)})")
      Logger.debug("consumer/#{stream_id}: state: #{inspect(state)}")
      ViewerTracker.untrack(stream_id)
    end

    :ok
  end

  # Private

  @session_key Keyword.fetch!(Application.compile_env!(:asciinema, :session_opts), :key)
  @signing_salt Keyword.fetch!(Application.compile_env!(:asciinema, :session_opts), :signing_salt)

  defp user_id_from_session(req) do
    cookies = :cowboy_req.parse_cookies(req)

    with {_, cookie} <- List.keyfind(cookies, @session_key, 0) do
      secret_key_base = Application.fetch_env!(:asciinema, Endpoint)[:secret_key_base]
      conn = %{secret_key_base: secret_key_base}
      opts = Plug.Session.COOKIE.init(signing_salt: @signing_salt)
      {:term, session} = Plug.Session.COOKIE.get(conn, cookie, opts)

      session["user_id"]
    end
  end

  defp fetch_live_stream(token) do
    case Streaming.get_live_stream(token) do
      nil -> {:error, :stream_not_found}
      stream -> {:ok, stream}
    end
  end

  defp authorize(stream, user_id) do
    if Authorization.can?(nil, :show, stream) ||
         Authorization.can?(Accounts.get_user(user_id), :show, stream) do
      :ok
    else
      {:error, :forbidden}
    end
  end

  defp header_message, do: {:binary, "ALiS\x01"}

  defp reset_message({vt_size, init, time, nil}) do
    {cols, rows} = vt_size
    init = init || ""
    init_len = byte_size(init)

    msg = <<
      # message type: reset
      1::8,
      # terminal width in columns
      cols::little-16,
      # terminal height in rows
      rows::little-16,
      # current stream time
      time::little-float-32,
      # theme format: none
      0::8,
      # length of the vt init payload
      init_len::little-32,
      # vt init payload
      init::binary
    >>

    {:binary, msg}
  end

  defp reset_message({vt_size, init, time, theme}) do
    {cols, rows} = vt_size
    theme_format = length(theme.palette)
    theme = encode_theme(theme)
    init = init || ""
    init_len = byte_size(init)

    msg = <<
      # message type: reset
      1::8,
      # terminal width in columns
      cols::little-16,
      # terminal height in rows
      rows::little-16,
      # current stream time
      time::little-float-32,
      # theme format: 8 or 16
      theme_format::8,
      # theme colors
      theme::binary,
      # length of the vt init payload
      init_len::little-32,
      # vt init payload
      init::binary
    >>

    {:binary, msg}
  end

  defp output_message(event) do
    {time, data} = event
    data_len = byte_size(data)

    msg = <<
      # message type: output
      ?o,
      # current stream time
      time::little-float-32,
      # output length
      data_len::little-32,
      # output payload
      data::binary
    >>

    {:binary, msg}
  end

  defp resize_message(event) do
    {time, {cols, rows}} = event

    msg = <<
      # message type: resize
      ?r,
      # current stream time
      time::little-float-32,
      # terminal width in columns
      cols::little-16,
      # terminal height in rows
      rows::little-16
    >>

    {:binary, msg}
  end

  defp offline_message do
    msg = <<
      # message type: offline (EOT, 0x04)
      0x04::8
    >>

    {:binary, msg}
  end

  defp encode_theme(%{fg: fg, bg: bg, palette: palette}) do
    for {r, g, b} <- [fg, bg | palette], into: <<>> do
      <<r::8, g::8, b::8>>
    end
  end
end
