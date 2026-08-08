defmodule AsciinemaWeb.StreamProducerSocketTest do
  # Drives the real socket callbacks, some against a running StreamServer
  # stack, hence not async.
  use Asciinema.DataCase

  import Asciinema.Factory
  import Plug.Conn
  import Plug.Test

  alias Asciinema.AppEnv
  alias Asciinema.Leb128
  alias Asciinema.Streaming
  alias Asciinema.Streaming.StreamServer
  alias AsciinemaWeb.StreamProducerSocket

  @magic "ALiS\x01"

  describe "connection" do
    test "negotiates a supported sub-protocol" do
      conn =
        "s3kr1t"
        |> build_upgrade_request(%{"sec-websocket-protocol" => "v1.alis"})
        |> upgrade()

      assert conn.state == :upgraded
      assert get_resp_header(conn, "sec-websocket-protocol") == ["v1.alis"]
    end

    test "rejects an unsupported sub-protocol" do
      conn =
        "s3kr1t"
        |> build_upgrade_request(%{"sec-websocket-protocol" => "lol"})
        |> upgrade()

      assert conn.state == :sent
      assert conn.status == 400
    end

    test "accepts a connection without a sub-protocol" do
      conn = "s3kr1t" |> build_upgrade_request(%{}) |> upgrade()

      assert conn.state == :upgraded
      assert get_resp_header(conn, "sec-websocket-protocol") == []
    end

    test "initializes the socket when the stream is found" do
      insert(:stream, producer_token: "s3kr1t", live: true)

      assert {:ok, _} = StreamProducerSocket.init(socket_params("s3kr1t"))
    end

    test "closes when the stream is not found" do
      assert {:stop, :stream_not_found, {4040, "stream not found"}, _} =
               StreamProducerSocket.init(socket_params("nope"))
    end
  end

  describe "ALiS message flow" do
    test "init starts the server, events flow with absolute times, EOT stops the server" do
      {stream, state} = open_socket()
      StreamServer.subscribe(stream.id, [:reset, :output, :end])

      {:ok, state} = handle(state, @magic)
      {:ok, state} = handle(state, init_frame(time: 500))

      assert_receive %StreamServer.Update{event: :reset, data: %{term_size: {80, 24}}}

      {:ok, state} = handle(state, output_frame(1, 100, "hello"))

      # relative wire time is accumulated onto the init time
      assert_receive %StreamServer.Update{
        event: :output,
        data: %{id: 1, time: 600, text: "hello"}
      }

      {:ok, state} = handle(state, eot_frame(2, 50))

      assert_receive %StreamServer.Update{event: :end, data: _}, 2_000

      # after EOT another init restarts the stream
      {:ok, _state} = handle(state, init_frame(time: 1_000))

      assert_receive %StreamServer.Update{event: :reset, data: _}
    end

    test "the negotiated protocol is persisted at connection time, before any frame" do
      {stream, _state} = open_socket()

      assert Streaming.get_stream(stream.id).protocol == "v1.alis"
    end

    test "invalid init dimensions close with 4003" do
      {_stream, state} = open_socket()

      {:ok, state} = handle(state, @magic)

      assert {:stop, :invalid_terminal_size, {4003, _}, _} =
               handle(state, init_frame(cols: 0))
    end

    test "unsupported ALiS version closes with 4005" do
      {_stream, state} = open_socket()

      assert {:stop, :message_parsing_error, {4005, _}, _} = handle(state, "ALiS\x02")
    end
  end

  describe "protocol auto-detection" do
    test "ALiS magic detects and persists the alis protocol" do
      {stream, state} = open_socket(protocol: nil)

      {:ok, _state} = handle(state, @magic)

      assert Streaming.get_stream(stream.id).protocol == "v1.alis"
    end

    test "an asciicast v2 header detects and persists, and the header initializes the stream" do
      {stream, state} = open_socket(protocol: nil)
      StreamServer.subscribe(stream.id, [:reset])

      header = Jason.encode!(%{version: 2, width: 96, height: 25})
      {:ok, state} = StreamProducerSocket.handle_in({header, opcode: :text}, state)

      assert Streaming.get_stream(stream.id).protocol == "v2.asciicast"
      assert_receive %StreamServer.Update{event: :reset, data: %{term_size: {96, 25}}}

      # a repeated header while online closes instead of crashing
      assert {:stop, :invalid_command, {4005, _}, _} =
               StreamProducerSocket.handle_in({header, opcode: :text}, state)
    end
  end

  describe "rate limiting" do
    test "an over-budget frame is rejected before parsing" do
      AppEnv.put(:stream_producer_bucket_size, 10)
      {_stream, state} = open_socket()

      {:ok, state} = handle(state, @magic)

      # this frame would close 4005 (unsupported ALiS version) if it were
      # parsed; over budget it closes 4004, proving no parsing happens
      assert {:stop, :bandwidth_exceeded, {4004, _}, _} =
               handle(state, "ALiS\x02 with some padding")
    end

    test "an over-budget first frame is rejected before protocol detection" do
      AppEnv.put(:stream_producer_bucket_size, 3)
      {stream, state} = open_socket(protocol: nil)

      assert {:stop, :bandwidth_exceeded, {4004, _}, _} =
               handle(state, "some long raw terminal output")

      # no parsing happened: the protocol was never detected or persisted
      assert Streaming.get_stream(stream.id).protocol == nil
    end
  end

  describe "terminate" do
    test "stops the server on remote close when the protocol calls for it" do
      {stream, state} = open_socket(protocol: "raw")
      StreamServer.subscribe(stream.id, [:reset, :end])

      {:ok, state} = handle(state, "raw output")
      assert_receive %StreamServer.Update{event: :reset, data: _}

      assert :ok = StreamProducerSocket.terminate(:remote, state)
      assert_receive %StreamServer.Update{event: :end, data: _}, 2_000
    end

    test "keeps the server when the protocol keeps it" do
      {stream, state} = open_socket()
      StreamServer.subscribe(stream.id, [:end])

      {:ok, state} = handle(state, @magic)
      {:ok, state} = handle(state, init_frame())

      assert :ok = StreamProducerSocket.terminate(:remote, state)
      refute_receive %StreamServer.Update{event: :end, data: _}, 500
    end

    test "keeps the server on non-remote close reasons" do
      {stream, state} = open_socket(protocol: "raw")
      StreamServer.subscribe(stream.id, [:reset, :end])

      {:ok, state} = handle(state, "raw output")
      assert_receive %StreamServer.Update{event: :reset, data: _}

      assert :ok = StreamProducerSocket.terminate(:closed, state)
      refute_receive %StreamServer.Update{event: :end, data: _}, 500
    end
  end

  # Helpers

  defp build_upgrade_request(producer_token, headers) do
    host = "localhost"

    required_headers = %{
      "connection" => "upgrade",
      "upgrade" => "websocket",
      "sec-websocket-key" => "dGhlIHNhbXBsZSBub25jZQ==",
      "sec-websocket-version" => "13",
      "user-agent" => "asciinema/3.0"
    }

    merged_headers = Map.merge(required_headers, headers)

    conn =
      Enum.reduce(merged_headers, conn(:get, "/ws/S/#{producer_token}"), fn {name, value}, conn ->
        put_req_header(conn, name, value)
      end)

    %{conn | host: host, req_headers: [{"host", host} | conn.req_headers]}
  end

  defp upgrade(conn) do
    path_params = Map.put_new(conn.path_params, "producer_token", List.last(conn.path_info))

    StreamProducerSocket.upgrade(conn, path_params)
  end

  defp socket_params(token) do
    %{token: token, protocol: "v1.alis", user_agent: "test/agent"}
  end

  defp open_socket(opts \\ []) do
    protocol = Keyword.get(opts, :protocol, "v1.alis")
    stream = insert(:stream, live: true)

    {:ok, state} =
      StreamProducerSocket.init(%{socket_params(stream.producer_token) | protocol: protocol})

    {stream, state}
  end

  defp handle(state, payload) do
    StreamProducerSocket.handle_in({payload, opcode: :binary}, state)
  end

  defp init_frame(opts \\ []) do
    <<1>> <>
      varint(opts[:last_id] || 0) <>
      varint(opts[:time] || 0) <>
      varint(opts[:cols] || 80) <>
      varint(opts[:rows] || 24) <>
      <<0>> <>
      varint(0)
  end

  defp output_frame(id, rel_time, text) do
    <<?o>> <> varint(id) <> varint(rel_time) <> varint(byte_size(text)) <> text
  end

  # legacy id + time EOT, as the CLI emits it
  defp eot_frame(id, rel_time) do
    <<0x04>> <> varint(id) <> varint(rel_time)
  end

  defp varint(n), do: Leb128.encode(n)
end
