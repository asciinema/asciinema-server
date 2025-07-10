defmodule AsciinemaWeb.Api.StreamControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory
  alias Asciinema.Accounts

  @next_link_regex ~r/<([^>]+)>; rel="next"/

  setup(context) do
    [token: Map.get(context, :token, "9da34ff4-9bf7-45d4-aa88-98c933b15a3f")]
  end

  describe "index without authentication" do
    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/user/streams")

      assert response(conn, 401)
    end
  end

  describe "index with invalid install ID" do
    setup [:authenticate]

    @tag token: "invalid-lol"
    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/user/streams")

      assert response(conn, 401)
    end
  end

  describe "index with revoked CLI" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/user/streams")

      assert response(conn, 401)
    end
  end

  describe "index with unregistered CLI" do
    setup [:authenticate]

    @tag user: [email: nil]
    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/user/streams")

      assert json_response(conn, 401)
    end
  end

  describe "index with registered CLI" do
    setup [:register_cli, :authenticate]

    test "responds with empty array when no streams exist for authenticated user", %{conn: conn} do
      insert(:stream)

      conn = get(conn, ~p"/api/v1/user/streams")

      assert [] = json_response(conn, 200)
    end

    test "responds with user's streams sorted by ID (asc)", %{conn: conn, cli: cli} do
      %{id: id1} =
        insert(:stream,
          user: cli.user,
          public_token: "foobar1234567890",
          producer_token: "bazqux1",
          title: "Stream 1"
        )

      %{id: id2} =
        insert(:stream,
          user: cli.user,
          public_token: "abcdef0987654321",
          producer_token: "bazqux2",
          title: "Stream 2"
        )

      insert(:stream, title: "Stream 3")

      conn = get(conn, ~p"/api/v1/user/streams")

      assert [
               %{
                 "id" => ^id1,
                 "url" => "http://localhost:4001/s/" <> _,
                 "ws_producer_url" => "ws://localhost:4001/ws/S/" <> _,
                 "audio_url" => _,
                 "title" => "Stream 1",
                 "description" => _,
                 "visibility" => _
               },
               %{
                 "id" => ^id2,
                 "url" => "http://localhost:4001/s/" <> _,
                 "ws_producer_url" => "ws://localhost:4001/ws/S/" <> _,
                 "audio_url" => _,
                 "title" => "Stream 2",
                 "description" => _,
                 "visibility" => _
               }
             ] = json_response(conn, 200)
    end

    test "filters streams by public token prefix", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user, public_token: "foobar1234567890", title: "Stream 1")
      insert(:stream, public_token: "fooxxx1234567890")
      insert(:stream, user: cli.user, public_token: "abcdef0987654321")

      conn = get(conn, ~p"/api/v1/user/streams?prefix=foo")

      assert [
               %{
                 "id" => _,
                 "url" => "http://localhost:4001/s/" <> _,
                 "ws_producer_url" => "ws://localhost:4001/ws/S/" <> _,
                 "audio_url" => _,
                 "title" => "Stream 1",
                 "description" => _,
                 "visibility" => _
               }
             ] = json_response(conn, 200)
    end

    test "limits results to 10 streams by default", %{conn: conn, cli: cli} do
      insert_list(12, :stream, user: cli.user)

      conn = get(conn, ~p"/api/v1/user/streams")

      streams = json_response(conn, 200)
      assert length(streams) == 10
    end

    test "respects hard limit of 100 for limit parameter", %{conn: conn, cli: cli} do
      insert_list(101, :stream, user: cli.user)

      conn = get(conn, ~p"/api/v1/user/streams?limit=150")

      streams = json_response(conn, 200)
      assert length(streams) == 100
    end

    test "provides pagination chain through Link headers", %{conn: conn, cli: cli} do
      streams = insert_list(10, :stream, user: cli.user)

      # Start with first page, no cursor/limit specified (should use defaults)
      conn = get(conn, ~p"/api/v1/user/streams?limit=3")
      response = json_response(conn, 200)
      assert length(response) == 3

      # Verify we got the first 3 streams
      expected_ids = streams |> Enum.take(3) |> Enum.map(& &1.id)
      actual_ids = response |> Enum.map(& &1["id"])
      assert actual_ids == expected_ids

      # Check Link header format and extract next URL
      [link_header] = get_resp_header(conn, "link")
      assert link_header =~ @next_link_regex
      next_url = Regex.run(@next_link_regex, link_header) |> List.last()

      # Assert on the shape of the next link
      assert next_url =~ ~r/\/api\/v1\/user\/streams\?cursor=[A-Za-z0-9+\/=%]+&limit=3/

      # Follow the next link
      conn = get(conn, next_url)
      response = json_response(conn, 200)
      assert length(response) == 3

      # Verify we got the next 3 streams
      expected_ids = streams |> Enum.drop(3) |> Enum.take(3) |> Enum.map(& &1.id)
      actual_ids = response |> Enum.map(& &1["id"])
      assert actual_ids == expected_ids

      # Check Link header and extract next URL
      [link_header] = get_resp_header(conn, "link")
      assert link_header =~ @next_link_regex
      next_url = Regex.run(@next_link_regex, link_header) |> List.last()

      # Follow the next link
      conn = get(conn, next_url)
      response = json_response(conn, 200)
      assert length(response) == 3

      # Verify we got the next 3 streams
      expected_ids = streams |> Enum.drop(6) |> Enum.take(3) |> Enum.map(& &1.id)
      actual_ids = response |> Enum.map(& &1["id"])
      assert actual_ids == expected_ids

      # Check Link header and extract next URL
      [link_header] = get_resp_header(conn, "link")
      assert link_header =~ @next_link_regex
      next_url = Regex.run(@next_link_regex, link_header) |> List.last()

      # Follow the next link - should be the last page
      conn = get(conn, next_url)
      response = json_response(conn, 200)
      assert length(response) == 1

      # Verify we got the last stream
      expected_ids = streams |> Enum.drop(9) |> Enum.take(1) |> Enum.map(& &1.id)
      actual_ids = response |> Enum.map(& &1["id"])
      assert actual_ids == expected_ids

      # No more pages - should have no Link header
      assert [] = get_resp_header(conn, "link")
    end

    test "preserves prefix in cursor", %{conn: conn, cli: cli} do
      %{id: id1} = insert(:stream, user: cli.user, public_token: "foo1234567890123")
      %{id: id2} = insert(:stream, user: cli.user, public_token: "foo1234567890124")
      %{id: id3} = insert(:stream, user: cli.user, public_token: "foo1234567890125")
      insert(:stream, user: cli.user, public_token: "bar1234567890123")

      # Start with first page with prefix filter "foo"
      conn = get(conn, ~p"/api/v1/user/streams?prefix=foo&limit=2")
      assert [%{"id" => ^id1}, %{"id" => ^id2}] = json_response(conn, 200)

      [link_header] = get_resp_header(conn, "link")
      next_url = Regex.run(@next_link_regex, link_header) |> List.last()

      # Follow the next link with prefix filter override (should be ignored)
      conn = get(conn, next_url <> "&prefix=bar")
      assert [%{"id" => ^id3}] = json_response(conn, 200)
    end

    @tag user: [streaming_enabled: false]
    test "responds with 403 when user has streaming disabled", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user)

      conn = get(conn, ~p"/api/v1/user/streams")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end
  end

  describe "create stream without authentication" do
    test "fails", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/streams")

      assert response(conn, 401)
    end
  end

  describe "create stream with invalid install ID" do
    setup [:authenticate]

    @tag token: "invalid-lol"
    test "fails", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/streams")

      assert response(conn, 401)
    end
  end

  describe "create stream with revoked CLI" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/streams")

      assert response(conn, 401)
    end
  end

  describe "create stream with unregistered CLI" do
    setup [:authenticate]

    @tag user: [email: nil]
    test "fails", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/streams")

      assert json_response(conn, 401)
    end
  end

  describe "create stream with registered CLI" do
    setup [:register_cli, :authenticate]

    @tag user: [streaming_enabled: true]
    test "succeeds when user has streaming enabled", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/streams")

      assert %{
               "id" => _,
               "url" => "http://localhost:4001/s/" <> _,
               "ws_producer_url" => "ws://localhost:4001/ws/S/" <> _,
               "audio_url" => nil,
               "live" => false,
               "title" => nil,
               "description" => nil,
               "visibility" => "unlisted"
             } = json_response(conn, 200)
    end

    @tag user: [streaming_enabled: false]
    test "fails when user has streaming disabled", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/streams")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    @tag user: [live_stream_limit: 2]
    test "succeeds for non-live stream when live stream limit reached", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user, live: false)
      insert_list(2, :stream, user: cli.user, live: true)

      # { live: false } is implicit here
      conn = post(conn, ~p"/api/v1/streams")

      assert json_response(conn, 200)
    end

    @tag user: [live_stream_limit: 2]
    test "succeeds for live stream when below live stream limit", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user, live: false)
      insert(:stream, user: cli.user, live: true)

      conn = post(conn, ~p"/api/v1/streams", %{live: true})

      assert json_response(conn, 200)
    end

    @tag user: [live_stream_limit: 0]
    test "fails for live stream when live stream limit is 0", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user, live: false)

      conn = post(conn, ~p"/api/v1/streams", %{live: true})

      assert %{"reason" => "live stream limit exceeded"} = json_response(conn, 422)
    end

    @tag user: [live_stream_limit: 2]
    test "fails for live stream when live stream limit reached", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user, live: false)
      insert_list(2, :stream, user: cli.user, live: true)

      conn = post(conn, ~p"/api/v1/streams", %{live: true})

      assert %{"reason" => "live stream limit exceeded"} = json_response(conn, 422)
    end
  end

  describe "create stream via legacy path" do
    # { live: true } is implicit here
    setup [:register_cli, :authenticate]

    test "succeeds when user has streaming enabled", %{conn: conn} do
      conn = post(conn, ~p"/api/streams")

      assert %{
               "url" => "http://localhost:4001/s/" <> _,
               "ws_producer_url" => "ws://localhost:4001/ws/S/" <> _
             } = json_response(conn, 200)
    end

    @tag user: [streaming_enabled: false]
    test "fails when user has streaming disabled", %{conn: conn} do
      conn = post(conn, ~p"/api/streams")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    @tag user: [live_stream_limit: 0]
    test "fails when live stream limit is 0", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user, live: false)

      conn = post(conn, ~p"/api/streams")

      assert %{"reason" => "live stream limit exceeded"} = json_response(conn, 422)
    end

    @tag user: [live_stream_limit: 2]
    test "fails when live stream limit reached", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user, live: false)
      insert_list(2, :stream, user: cli.user, live: true)

      conn = post(conn, ~p"/api/streams")

      assert %{"reason" => "live stream limit exceeded"} = json_response(conn, 422)
    end
  end

  describe "update without authentication" do
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = put(conn, ~p"/api/v1/streams/#{stream.id}", %{"title" => "New title"})

      assert response(conn, 401)
    end
  end

  describe "update with invalid install ID" do
    setup [:authenticate]

    @tag token: "invalid-lol"
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = put(conn, ~p"/api/v1/streams/#{stream.id}", %{"title" => "New title"})

      assert response(conn, 401)
    end
  end

  describe "update with revoked install ID" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = put(conn, ~p"/api/v1/streams/#{stream.id}", %{"title" => "New title"})

      assert response(conn, 401)
    end
  end

  describe "update with unregistered CLI" do
    setup [:authenticate]

    @tag user: [email: nil]
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = put(conn, ~p"/api/v1/streams/#{stream.id}", %{"title" => "New title"})

      assert response(conn, 401)
    end
  end

  describe "update with registered CLI" do
    setup [:register_cli, :authenticate]

    test "succeeds when attrs are valid", %{conn: conn, cli: cli} do
      stream =
        insert(:stream,
          user: cli.user,
          public_token: "foobar1234567890",
          producer_token: "bazqux",
          title: "Original title",
          description: "Original description"
        )

      conn =
        put(conn, ~p"/api/v1/streams/#{stream.id}", %{
          "title" => "New title",
          "description" => "New description",
          "audio_url" => "http://icecast.example.com/stream"
        })

      assert %{
               "id" => _,
               "url" => "http://localhost:4001/s/foobar1234567890",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux",
               "audio_url" => "http://icecast.example.com/stream",
               "title" => "New title",
               "live" => false,
               "description" => "New description",
               "visibility" => "unlisted"
             } = json_response(conn, 200)
    end

    test "succeeds when using public token", %{conn: conn, cli: cli} do
      _stream =
        insert(:stream,
          user: cli.user,
          public_token: "foobar1234567890",
          producer_token: "bazqux",
          title: "Original title"
        )

      conn =
        put(conn, ~p"/api/v1/streams/foobar1234567890", %{
          "title" => "New title via token"
        })

      assert %{
               "id" => _,
               "url" => "http://localhost:4001/s/foobar1234567890",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux",
               "title" => "New title via token",
               "visibility" => "unlisted"
             } = json_response(conn, 200)
    end

    test "fails when attrs are not valid", %{conn: conn, cli: cli} do
      stream = insert(:stream, user: cli.user)

      conn = put(conn, ~p"/api/v1/streams/#{stream.id}", %{"buffer_time" => -1})

      assert json_response(conn, 422)["errors"]["buffer_time"] != nil
    end

    @tag user: [streaming_enabled: false]
    test "fails when streaming is disabled", %{conn: conn, cli: cli} do
      stream = insert(:stream, user: cli.user)

      conn = put(conn, ~p"/api/v1/streams/#{stream.id}", %{"title" => "New title"})

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    @tag user: [live_stream_limit: 2]
    test "succeeds when setting live while below live stream limit", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user, live: true)
      stream = insert(:stream, user: cli.user, live: false)

      conn = put(conn, ~p"/api/v1/streams/#{stream.id}", %{live: true})

      assert %{"live" => true} = json_response(conn, 200)
    end

    @tag user: [live_stream_limit: 2]
    test "fails when setting live while live stream limit hit", %{conn: conn, cli: cli} do
      insert_list(2, :stream, user: cli.user, live: true)
      stream = insert(:stream, user: cli.user, live: false)

      conn = put(conn, ~p"/api/v1/streams/#{stream.id}", %{live: true})

      assert %{"reason" => "live stream limit exceeded"} = json_response(conn, 422)
    end

    test "fails when stream is not found", %{conn: conn} do
      conn = put(conn, ~p"/api/v1/streams/99999", %{"title" => "New title"})

      assert %{"error" => "stream not found"} = json_response(conn, 404)
    end
  end

  describe "make live via legacy path" do
    setup [:register_cli, :authenticate]

    @tag user: [live_stream_limit: 2]
    test "succeeds when below live stream limit", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user, live: true)
      insert(:stream, user: cli.user, live: false, public_token: "foobar1234567890")

      conn = get(conn, ~p"/api/user/streams/foob")

      assert %{"live" => true} = json_response(conn, 200)
    end

    @tag user: [live_stream_limit: 2]
    test "fails when live stream limit hit", %{conn: conn, cli: cli} do
      insert_list(2, :stream, user: cli.user, live: true)
      insert(:stream, user: cli.user, live: false, public_token: "foobar1234567890")

      conn = get(conn, ~p"/api/user/streams/foob")

      assert %{"reason" => "live stream limit exceeded"} = json_response(conn, 422)
    end

    test "fails when stream is not found", %{conn: conn} do
      conn = get(conn, ~p"/api/user/streams/99999")

      assert %{"error" => "stream not found"} = json_response(conn, 404)
    end
  end

  describe "delete without authentication" do
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/api/v1/streams/#{stream.id}")

      assert response(conn, 401)
    end
  end

  describe "delete with invalid install ID" do
    setup [:authenticate]

    @tag token: "invalid-lol"
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/api/v1/streams/#{stream.id}")

      assert response(conn, 401)
    end
  end

  describe "delete with revoked install ID" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/api/v1/streams/#{stream.id}")

      assert response(conn, 401)
    end
  end

  describe "delete with unregistered CLI" do
    setup [:authenticate]

    @tag user: [email: nil]
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/api/v1/streams/#{stream.id}")

      assert response(conn, 401)
    end
  end

  describe "delete with registered CLI" do
    setup [:register_cli, :authenticate]

    test "succeeds when deleting own stream", %{conn: conn, cli: cli} do
      stream = insert(:stream, user: cli.user)

      conn = delete(conn, ~p"/api/v1/streams/#{stream.id}")

      assert response(conn, 204)
    end

    test "succeeds when deleting own stream using public token", %{conn: conn, cli: cli} do
      _stream = insert(:stream, user: cli.user, public_token: "foobar1234567890")

      conn = delete(conn, ~p"/api/v1/streams/foobar1234567890")

      assert response(conn, 204)
    end

    test "fails when stream belongs to another user", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/api/v1/streams/#{stream.id}")

      assert json_response(conn, 403)["error"] == "Forbidden"
    end

    @tag user: [streaming_enabled: false]
    test "fails when streaming is disabled", %{conn: conn, cli: cli} do
      stream = insert(:stream, user: cli.user)

      conn = delete(conn, ~p"/api/v1/streams/#{stream.id}")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    test "fails when stream is not found", %{conn: conn} do
      conn = delete(conn, ~p"/api/v1/streams/99999")

      assert json_response(conn, 404)["error"] == "stream not found"
    end
  end

  defp register_cli(%{token: token} = context) do
    user = insert(:user, Map.get(context, :user, []))
    cli = insert(:cli, user: user, token: token)

    [cli: cli]
  end

  defp revoke_cli(%{cli: cli}) do
    [cli: Accounts.revoke_cli!(cli)]
  end

  defp authenticate(%{conn: conn, token: token}) do
    conn =
      if token do
        put_req_header(conn, "authorization", "Basic " <> Base.encode64(":" <> token))
      else
        conn
      end

    [conn: conn]
  end
end
