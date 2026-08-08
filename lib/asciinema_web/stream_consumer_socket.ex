defmodule AsciinemaWeb.StreamConsumerSocket do
  import Plug.Conn

  alias Asciinema.{Accounts, Streaming}
  alias Asciinema.Streaming.Alis
  alias Asciinema.Streaming.{ConsumerSession, StreamServer, ViewerTracker}
  alias AsciinemaWeb.Authorization
  require Logger

  @behaviour WebSock

  @protocol "v1.alis"
  @client_ping_interval 15_000

  def upgrade(conn, %{"public_token" => public_token}) do
    protocol = negotiated_protocol(conn)

    params = %{
      token: public_token,
      user_id: user_id_from_session(conn),
      stream_id: nil,
      protocol: protocol
    }

    if protocol do
      conn
      |> put_resp_header("sec-websocket-protocol", @protocol)
      |> do_upgrade(params, compress: true)
    else
      do_upgrade(conn, params, compress: false)
    end
  end

  defp do_upgrade(conn, params, opts) do
    conn
    |> WebSockAdapter.upgrade(__MODULE__, params, opts)
    |> halt()
  end

  # WebSock callbacks

  @impl true
  def init(%{protocol: nil} = state) do
    {:stop, :protocol_negotiation_failed, {1002, "protocol negotiation failed"}, state}
  end

  def init(%{token: token, user_id: user_id}) do
    with {:ok, stream} <- fetch_stream(token),
         :ok <- authorize(stream, user_id) do
      Logger.info("consumer/#{stream.id}: connected")
      state = %{stream_id: stream.id, session: ConsumerSession.new()}
      StreamServer.subscribe(stream.id, [:output, :input, :resize, :marker, :end, :reset])
      StreamServer.request_info(stream.id)
      ViewerTracker.track(stream.id)
      Process.send_after(self(), :client_ping, @client_ping_interval)

      {:push, {:binary, Alis.V1.magic()}, state}
    else
      {:error, :stream_not_found} ->
        Logger.info("consumer: stream not found for public token #{token}")
        :timer.sleep(1000)

        {:stop, :stream_not_found, {4040, "stream not found"}, %{stream_id: "?"}}

      {:error, :forbidden} ->
        Logger.info("consumer: unauthorized connection attempt")

        {:stop, :forbidden, {4030, "unauthorized"}, %{stream_id: token}}
    end
  end

  @impl true
  def handle_in(_frame, state), do: {:ok, state}

  @impl true
  def handle_info(message, state)

  def handle_info(%StreamServer.Update{event: event, data: data}, state) do
    log_update(event, data, state)

    case ConsumerSession.handle_event(state.session, event, data) do
      {nil, session} ->
        {:ok, %{state | session: session}}

      {frame, session} ->
        {:push, {:binary, frame}, %{state | session: session}}
    end
  end

  def handle_info(:client_ping, state) do
    Process.send_after(self(), :client_ping, @client_ping_interval)

    {:push, {:ping, ""}, state}
  end

  @impl true
  def terminate(reason, state) do
    stream_id = state[:stream_id] || state[:token] || "?"
    Logger.info("consumer/#{stream_id}: terminating (#{inspect(reason)})")
    Logger.debug("consumer/#{stream_id}: state: #{inspect(state)}")

    if stream_id = state[:stream_id] do
      ViewerTracker.untrack(stream_id)
    end

    :ok
  end

  # Private

  defp user_id_from_session(conn) do
    conn
    |> fetch_session()
    |> get_session("user_id")
  end

  defp fetch_stream(token) do
    case Streaming.lookup_stream(token) do
      nil -> {:error, :stream_not_found}
      stream -> {:ok, stream}
    end
  end

  defp authorize(stream, user_id) do
    if Authorization.can?(nil, :show, stream) ||
         (user_id && Authorization.can?(Accounts.get_user(user_id), :show, stream)) do
      :ok
    else
      {:error, :forbidden}
    end
  end

  defp requested_protocols(conn) do
    conn
    |> get_req_header("sec-websocket-protocol")
    |> Enum.flat_map(&Plug.Conn.Utils.list/1)
  end

  defp negotiated_protocol(conn) do
    if Enum.member?(requested_protocols(conn), @protocol), do: @protocol
  end

  defp log_update(:reset, %{term_size: {cols, rows}}, state) do
    Logger.debug("consumer/#{state.stream_id}: init (#{cols}x#{rows})")
  end

  defp log_update(:info, %{term_size: {cols, rows}}, %{session: %{init: false}} = state) do
    Logger.debug("consumer/#{state.stream_id}: info (#{cols}x#{rows})")
  end

  defp log_update(_event, _data, _state), do: :ok
end
