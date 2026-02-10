defmodule AsciinemaWeb.StreamProducerSocketTest do
  use Asciinema.DataCase
  import Asciinema.Factory
  import Plug.Conn
  import Plug.Test

  alias AsciinemaWeb.StreamProducerSocket

  describe "connection" do
    test "successful sub-protocol negotiation, stream found" do
      insert(:stream, producer_token: "s3kr1t", live: true)

      assert {:ok, _} = connect("s3kr1t", %{"sec-websocket-protocol" => "v1.alis"})
    end

    test "successful sub-protocol negotiation, stream not found" do
      assert {:stop, :stream_not_found, {4040, "stream not found"}, _} =
               connect("nope", %{"sec-websocket-protocol" => "v1.alis"})
    end

    test "failed sub-protocol negotiation" do
      conn =
        "s3kr1t"
        |> build_upgrade_request(%{"sec-websocket-protocol" => "lol"})
        |> upgrade()

      {Plug.Adapters.Test.Conn, %{ref: ref}} = conn.adapter

      assert conn.state == :sent
      assert_received {^ref, {400, _, _}}
      refute_received {^ref, :upgrade, _}
    end

    test "sub-protocol auto-detection, stream found" do
      insert(:stream, producer_token: "s3kr1t", live: true)

      assert {:ok, _} = connect("s3kr1t")
    end

    test "sub-protocol auto-detection, stream not found" do
      assert {:stop, :stream_not_found, {4040, "stream not found"}, _} = connect("nope")
    end
  end

  describe "detect_protocol/1" do
    test "alis v1" do
      assert StreamProducerSocket.detect_protocol({:binary, "ALiS\x01"}) == "v1.alis"
    end

    test "asciicast v2" do
      assert StreamProducerSocket.detect_protocol({:text, ~s|{"version": 2}|}) == "v2.asciicast"
    end

    test "asciicast v3" do
      assert StreamProducerSocket.detect_protocol({:text, ~s|{"version": 3}|}) == "v3.asciicast"
    end

    test "raw" do
      assert StreamProducerSocket.detect_protocol({:binary, "hello"}) == "raw"
    end

    test "other text falls back to raw" do
      assert StreamProducerSocket.detect_protocol({:text, ~s|{}|}) == "raw"
      assert StreamProducerSocket.detect_protocol({:text, ~s|hola!|}) == "raw"
    end
  end

  defp connect(producer_token, headers \\ %{}) do
    conn =
      producer_token
      |> build_upgrade_request(headers)
      |> upgrade()

    {Plug.Adapters.Test.Conn, %{ref: ref}} = conn.adapter

    assert conn.state == :upgraded
    assert_received {^ref, :upgrade, {:websocket, {StreamProducerSocket, params, opts}}}
    assert Keyword.get(opts, :compress) == true

    StreamProducerSocket.init(params)
  end

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
end
