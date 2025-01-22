defmodule AsciinemaWeb.LiveStreamConsumerSocket do
  alias Asciinema.{Accounts, Authorization, Streaming}
  alias Asciinema.Streaming.{LiveStreamServer, ViewerTracker}
  alias AsciinemaWeb.Endpoint
  require Logger

  @behaviour :cowboy_websocket

  @protocol "v1.alis"
  @client_ping_interval 15_000

  # Callbacks

  @impl true
  def init(req, _opts) do
    params = %{
      token: req.bindings[:public_token],
      user_id: user_id_from_session(req),
      stream_id: nil,
      protocol: nil
    }

    case :cowboy_req.parse_header("sec-websocket-protocol", req) do
      :undefined ->
        {:cowboy_websocket, req, params}

      protos ->
        if Enum.member?(protos, @protocol) do
          req = :cowboy_req.set_resp_header("sec-websocket-protocol", @protocol, req)
          {:cowboy_websocket, req, %{params | protocol: @protocol}, %{compress: true}}
        else
          {:cowboy_websocket, req, params}
        end
    end
  end

  @impl true
  def websocket_init(%{protocol: nil} = state) do
    {:reply, {:close, 1002, "protocol negotiation failed"}, state}
  end

  def websocket_init(%{token: token, user_id: user_id}) do
    with {:ok, stream} <- fetch_live_stream(token),
         :ok <- authorize(stream, user_id) do
      Logger.info("consumer/#{stream.id}: connected")
      state = %{stream_id: stream.id, reset: false}
      LiveStreamServer.subscribe(stream.id, [:output, :input, :resize, :marker, :offline, :reset])
      LiveStreamServer.request_info(stream.id)
      ViewerTracker.track(stream.id)
      Process.send_after(self(), :client_ping, @client_ping_interval)

      {:reply, magic_string(), state}
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

  def websocket_info(%LiveStreamServer.Update{event: :reset} = update, state) do
    %{term_size: {cols, rows}} = update.data
    Logger.debug("consumer/#{state.stream_id}: reset (#{cols}x#{rows})")

    {:reply,
     init_message(
       update.data.time,
       update.data.term_size,
       update.data[:term_init],
       update.data[:term_theme]
     ), %{state | reset: true}}
  end

  def websocket_info(%LiveStreamServer.Update{event: :info} = update, %{reset: false} = state) do
    %{term_size: {cols, rows}} = update.data
    Logger.debug("consumer/#{state.stream_id}: info (#{cols}x#{rows})")

    {:reply,
     init_message(
       update.data.time,
       update.data.term_size,
       update.data.term_init,
       update.data.term_theme
     ), %{state | reset: true}}
  end

  def websocket_info(%LiveStreamServer.Update{event: :info}, state) do
    {:ok, state}
  end

  def websocket_info(%LiveStreamServer.Update{}, %{reset: false} = state) do
    {:ok, state}
  end

  def websocket_info(%LiveStreamServer.Update{event: :output} = update, state) do
    {time, text} = update.data

    {:reply, output_message(time, text), state}
  end

  def websocket_info(%LiveStreamServer.Update{event: :input} = update, state) do
    {time, text} = update.data

    {:reply, input_message(time, text), state}
  end

  def websocket_info(%LiveStreamServer.Update{event: :resize} = update, state) do
    {time, term_size} = update.data

    {:reply, resize_message(time, term_size), state}
  end

  def websocket_info(%LiveStreamServer.Update{event: :marker} = update, state) do
    {time, label} = update.data

    {:reply, marker_message(time, label), state}
  end

  def websocket_info(%LiveStreamServer.Update{event: :offline}, state) do
    {:reply, offline_message(), state}
  end

  def websocket_info(:client_ping, state) do
    Process.send_after(self(), :client_ping, @client_ping_interval)

    {:reply, :ping, state}
  end

  @impl true
  def terminate(reason, _req, state) do
    stream_id = state[:stream_id] || state[:token] || "?"
    Logger.info("consumer/#{stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("consumer/#{stream_id}: state: #{inspect(state)}")

    if stream_id = state[:stream_id] do
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

  defp magic_string, do: {:binary, "ALiS\x01"}

  defp init_message(time, term_size, term_init, nil) do
    {cols, rows} = term_size
    term_init = term_init || ""
    term_init_len = byte_size(term_init)

    msg = <<
      # message type: init
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
      term_init_len::little-32,
      # vt init payload
      term_init::binary
    >>

    {:binary, msg}
  end

  defp init_message(time, term_size, term_init, theme) do
    {cols, rows} = term_size
    theme_format = length(theme.palette)
    true = theme_format in [8, 16]
    theme = encode_theme(theme)
    term_init = term_init || ""
    term_init_len = byte_size(term_init)

    msg = <<
      # message type: init
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
      term_init_len::little-32,
      # vt init payload
      term_init::binary
    >>

    {:binary, msg}
  end

  defp output_message(time, text) do
    text_len = byte_size(text)

    msg = <<
      # message type: output
      ?o,
      # current stream time
      time::little-float-32,
      # output length
      text_len::little-32,
      # output payload
      text::binary
    >>

    {:binary, msg}
  end

  defp input_message(time, text) do
    text_len = byte_size(text)

    msg = <<
      # message type: input
      ?i,
      # current stream time
      time::little-float-32,
      # input length
      text_len::little-32,
      # input payload
      text::binary
    >>

    {:binary, msg}
  end

  defp resize_message(time, term_size) do
    {cols, rows} = term_size

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

  defp marker_message(time, label) do
    label_len = byte_size(label)

    msg = <<
      # message type: marker
      ?m,
      # current stream time
      time::little-float-32,
      # marker label length
      label_len::little-32,
      # marker label payload
      label::binary
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
