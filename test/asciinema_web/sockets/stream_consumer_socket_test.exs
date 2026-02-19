defmodule AsciinemaWeb.StreamConsumerSocketTest do
  use Asciinema.DataCase, async: true
  import Asciinema.Factory
  import Plug.Conn
  import Plug.Test

  alias AsciinemaWeb.StreamConsumerSocket

  @headers %{"sec-websocket-protocol" => "v1.alis"}

  describe "connection" do
    test "successful protocol negotiation, public stream found" do
      stream = insert(:stream, visibility: :public)

      assert {:push, {:binary, "ALiS\x01"}, _} = connect(stream.public_token, @headers)
    end

    test "successful protocol negotiation, unlisted stream found" do
      stream = insert(:stream)

      assert {:push, {:binary, "ALiS\x01"}, _} = connect(stream.public_token, @headers)
    end

    test "successful protocol negotiation, stream not found" do
      assert {:stop, :stream_not_found, {4040, "stream not found"}, %{stream_id: "?"}} =
               connect("nope1234567890ab", @headers)
    end

    test "private stream, guest user, forbidden" do
      stream = insert(:stream, visibility: :private)

      assert {:stop, :forbidden, {4030, "unauthorized"}, %{stream_id: token}} =
               connect(stream.public_token, @headers)

      assert token == stream.public_token
    end

    test "private stream, owner user, allowed" do
      owner = insert(:user)
      stream = insert(:stream, visibility: :private, user: owner)

      assert {:push, {:binary, "ALiS\x01"}, _} = connect(stream.public_token, @headers, owner.id)
    end

    test "no protocol header, negotiation fails" do
      conn =
        "nope1234567890ab"
        |> build_upgrade_request()
        |> upgrade()

      {Plug.Adapters.Test.Conn, %{ref: ref}} = conn.adapter

      assert conn.state == :upgraded
      assert_received {^ref, :upgrade, {:websocket, {StreamConsumerSocket, params, opts}}}
      assert Keyword.get(opts, :compress) == false

      assert {:stop, :protocol_negotiation_failed, {1002, "protocol negotiation failed"}, _} =
               StreamConsumerSocket.init(params)
    end

    test "unsupported protocol header, negotiation fails" do
      conn =
        "nope1234567890ab"
        |> build_upgrade_request(%{"sec-websocket-protocol" => "nope"})
        |> upgrade()

      {Plug.Adapters.Test.Conn, %{ref: ref}} = conn.adapter

      assert conn.state == :upgraded
      assert_received {^ref, :upgrade, {:websocket, {StreamConsumerSocket, params, _opts}}}

      assert {:stop, :protocol_negotiation_failed, {1002, "protocol negotiation failed"}, _} =
               StreamConsumerSocket.init(params)
    end
  end

  defp connect(public_token, headers, user_id \\ nil) do
    conn =
      public_token
      |> build_upgrade_request(headers, user_id)
      |> upgrade()

    {Plug.Adapters.Test.Conn, %{ref: ref}} = conn.adapter

    assert conn.state == :upgraded
    assert_received {^ref, :upgrade, {:websocket, {StreamConsumerSocket, params, opts}}}
    assert Keyword.get(opts, :compress) == true

    StreamConsumerSocket.init(params)
  end

  defp build_upgrade_request(public_token, headers \\ %{}, user_id \\ nil) do
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

    session = if user_id, do: %{user_id: user_id}, else: %{}
    conn = init_test_session(conn, session)

    %{conn | host: host, req_headers: [{"host", host} | conn.req_headers]}
  end

  defp upgrade(conn) do
    path_params = Map.put_new(conn.path_params, "public_token", List.last(conn.path_info))

    StreamConsumerSocket.upgrade(conn, path_params)
  end
end
