defmodule AsciinemaWeb.StreamConsumerSocketTest do
  use Asciinema.DataCase, async: true
  import Asciinema.Factory
  import Plug.Conn
  import Plug.Test

  alias Asciinema.Streaming.Alis
  alias Asciinema.Streaming.StreamServer
  alias AsciinemaWeb.StreamConsumerSocket

  @headers %{"sec-websocket-protocol" => "v1.alis"}

  describe "connection" do
    test "negotiates the ALiS protocol" do
      conn = "token" |> build_upgrade_request(@headers) |> upgrade()

      assert conn.state == :upgraded
      assert get_resp_header(conn, "sec-websocket-protocol") == ["v1.alis"]
    end

    test "does not negotiate without a protocol header" do
      conn = "token" |> build_upgrade_request() |> upgrade()

      assert conn.state == :upgraded
      assert get_resp_header(conn, "sec-websocket-protocol") == []
    end

    test "does not negotiate an unsupported protocol" do
      conn =
        "token"
        |> build_upgrade_request(%{"sec-websocket-protocol" => "nope"})
        |> upgrade()

      assert conn.state == :upgraded
      assert get_resp_header(conn, "sec-websocket-protocol") == []
    end

    test "closes after protocol negotiation fails" do
      assert {:stop, :protocol_negotiation_failed, {1002, "protocol negotiation failed"}, _} =
               StreamConsumerSocket.init(%{protocol: nil})
    end

    test "allows a public stream" do
      stream = insert(:stream, visibility: :public)

      assert {:push, {:binary, "ALiS\x01"}, _} =
               StreamConsumerSocket.init(socket_params(stream.public_token))
    end

    test "allows an unlisted stream" do
      stream = insert(:stream)

      assert {:push, {:binary, "ALiS\x01"}, _} =
               StreamConsumerSocket.init(socket_params(stream.public_token))
    end

    test "closes when the stream is not found" do
      assert {:stop, :stream_not_found, {4040, "stream not found"}, _} =
               StreamConsumerSocket.init(socket_params("nope1234567890ab"))
    end

    test "rejects a guest from a private stream" do
      stream = insert(:stream, visibility: :private)

      assert {:stop, :forbidden, {4030, "unauthorized"}, _} =
               StreamConsumerSocket.init(socket_params(stream.public_token))
    end

    test "allows the owner of a private stream" do
      owner = insert(:user)
      stream = insert(:stream, visibility: :private, user: owner)

      assert {:push, {:binary, "ALiS\x01"}, _} =
               StreamConsumerSocket.init(socket_params(stream.public_token, owner.id))
    end
  end

  defp build_upgrade_request(public_token, headers \\ %{}) do
    host = "localhost"

    required_headers = %{
      "connection" => "upgrade",
      "upgrade" => "websocket",
      "sec-websocket-key" => "dGhlIHNhbXBsZSBub25jZQ==",
      "sec-websocket-version" => "13"
    }

    merged_headers = Map.merge(required_headers, headers)

    conn =
      Enum.reduce(merged_headers, conn(:get, "/ws/s/#{public_token}"), fn {name, value}, conn ->
        put_req_header(conn, name, value)
      end)

    conn = init_test_session(conn, %{})

    %{conn | host: host, req_headers: [{"host", host} | conn.req_headers]}
  end

  defp upgrade(conn) do
    path_params = Map.put_new(conn.path_params, "public_token", List.last(conn.path_info))

    StreamConsumerSocket.upgrade(conn, path_params)
  end

  defp socket_params(token, user_id \\ nil) do
    %{token: token, user_id: user_id, protocol: "v1.alis"}
  end

  describe "handle_info/2 with stream updates" do
    test "forwards stream updates as ALiS frames" do
      stream = insert(:stream, visibility: :public)

      assert {:push, {:binary, "ALiS\x01"}, state} =
               StreamConsumerSocket.init(socket_params(stream.public_token))

      info =
        stream_update(stream.id, :info, %{
          last_id: 0,
          time: 100,
          term_size: {80, 24},
          term_theme: nil,
          term_init: ""
        })

      assert {:push, {:binary, <<1, _rest::binary>>}, state} =
               StreamConsumerSocket.handle_info(info, state)

      output = stream_update(stream.id, :output, %{id: 2, time: 350, text: "x"})
      assert {:push, {:binary, frame}, _state} = StreamConsumerSocket.handle_info(output, state)

      # The delta proves the state returned for the init update was retained.
      assert frame == Alis.V1.encode_frame({:output, %{id: 2, rel_time: 250, text: "x"}})
    end
  end

  defp stream_update(stream_id, event, data) do
    %StreamServer.Update{stream_id: stream_id, event: event, data: data}
  end
end
