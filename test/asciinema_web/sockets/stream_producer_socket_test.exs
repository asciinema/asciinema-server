defmodule AsciinemaWeb.StreamProducerSocketTest do
  use Asciinema.DataCase
  import Asciinema.Factory
  alias AsciinemaWeb.StreamProducerSocket

  describe "connection" do
    test "successful sub-protocol negotiation, stream found" do
      insert(:stream, producer_token: "s3kr1t", live: true)

      assert {:ok, _} = connect("s3kr1t", %{"sec-websocket-protocol" => "v1.alis"})
    end

    test "successful sub-protocol negotiation, stream not found" do
      assert {:reply, {:close, 4040, "stream not found"}, _} =
               connect("nope", %{"sec-websocket-protocol" => "v1.alis"})
    end

    test "failed sub-protocol negotiation" do
      assert {:ok, %{has_sent_resp: true, bindings: _, headers: _}, _params} =
               connect("s3kr1t", %{"sec-websocket-protocol" => "lol"})

      assert_received {_, {:response, 400, _, _}}
    end

    test "sub-protocol auto-detection, stream found" do
      insert(:stream, producer_token: "s3kr1t", live: true)

      assert {:ok, _} = connect("s3kr1t")
    end

    test "sub-protocol auto-detection, stream not found" do
      assert {:reply, {:close, 4040, "stream not found"}, _} = connect("nope")
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
    req = build_cowboy_request(producer_token, headers)

    with {:cowboy_websocket, _req, params, %{compress: true}} <-
           StreamProducerSocket.init(req, []) do
      StreamProducerSocket.websocket_init(params)
    end
  end

  defp build_cowboy_request(producer_token, headers) do
    %{
      bindings: %{producer_token: producer_token},
      headers: Map.merge(%{"user-agent" => "asciinema/3.0"}, headers),
      qs: "foo=1&bar=2",
      pid: self(),
      streamid: "id"
    }
  end
end
