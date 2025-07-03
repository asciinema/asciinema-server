defmodule AsciinemaWeb.Api.StreamControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory
  alias Asciinema.Accounts

  setup(context) do
    [token: Map.get(context, :token, "9da34ff4-9bf7-45d4-aa88-98c933b15a3f")]
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

    test "responds with new stream info when no stream limit", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/streams")

      assert %{
               "id" => _,
               "url" => "http://localhost:4001/s/" <> _,
               "ws_producer_url" => "ws://localhost:4001/ws/S/" <> _
             } = json_response(conn, 200)
    end

    @tag user: [stream_limit: 2]
    test "responds with new stream info when below stream limit", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/streams")

      assert %{
               "url" => "http://localhost:4001/s/" <> _,
               "ws_producer_url" => "ws://localhost:4001/ws/S/" <> _
             } = json_response(conn, 200)
    end

    @tag user: [stream_limit: 1]
    test "responds with existing stream when stream limit reached and exactly 1 stream exists", %{
      conn: conn,
      cli: cli
    } do
      insert(:stream, user: cli.user, public_token: "foobar", producer_token: "bazqux")

      conn = post(conn, ~p"/api/v1/streams")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end

    @tag user: [streaming_enabled: false]
    test "responds with 403 when user has streaming disabled", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user)

      conn = post(conn, ~p"/api/v1/streams")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    @tag user: [stream_limit: 0]
    test "responds with 404 when no stream is available", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/streams")

      assert %{} = json_response(conn, 404)
    end

    @tag user: [stream_limit: 2]
    test "responds with 422 when stream limit reached and 2+ streams available", %{
      conn: conn,
      cli: cli
    } do
      insert_list(2, :stream, user: cli.user)

      conn = post(conn, ~p"/api/v1/streams")

      assert %{"reason" => "no default stream found"} = json_response(conn, 422)
    end
  end

  describe "create stream via legacy path" do
    setup [:register_cli, :authenticate]

    test "responds with new stream", %{conn: conn} do
      conn = post(conn, ~p"/api/streams")

      assert %{
               "url" => "http://localhost:4001/s/" <> _,
               "ws_producer_url" => "ws://localhost:4001/ws/S/" <> _
             } = json_response(conn, 200)
    end
  end

  describe "get default stream without authentication" do
    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/user/stream")

      assert response(conn, 401)
    end
  end

  describe "get default stream with invalid install ID" do
    setup [:authenticate]

    @tag token: "invalid-lol"
    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/user/stream")

      assert response(conn, 401)
    end
  end

  describe "get default stream with revoked CLI" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/user/stream")

      assert response(conn, 401)
    end
  end

  describe "get default stream with unregistered CLI" do
    setup [:authenticate]

    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/user/stream")

      assert json_response(conn, 401)
    end
  end

  describe "get default stream with registered CLI" do
    setup [:register_cli, :authenticate]

    test "responds with stream info when exactly 1 stream exists", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user, public_token: "foobar", producer_token: "bazqux")

      conn = get(conn, ~p"/api/user/stream")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end

    @tag user: [streaming_enabled: false]
    test "responds with 403 when user has streaming disabled", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user)

      conn = get(conn, ~p"/api/user/stream")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    test "responds with 404 when no stream is available", %{conn: conn} do
      conn = get(conn, ~p"/api/user/stream")

      assert %{} = json_response(conn, 404)
    end

    test "responds with 422 when more than one fixed stream is available", %{conn: conn, cli: cli} do
      insert_list(2, :stream, user: cli.user)

      conn = get(conn, ~p"/api/user/stream")

      assert %{"reason" => "no default stream found"} = json_response(conn, 422)
    end
  end

  describe "get stream by ID without authentication" do
    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/user/streams/x")

      assert response(conn, 401)
    end
  end

  describe "get stream by ID with invalid install ID" do
    setup [:authenticate]

    @tag token: "invalid-lol"
    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/user/streams/x")

      assert response(conn, 401)
    end
  end

  describe "get stream by ID with revoked install ID" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/user/streams/x")

      assert response(conn, 401)
    end
  end

  describe "get stream by ID with unregistered CLI" do
    setup [:authenticate]

    test "fails", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/user/streams/x")

      assert json_response(conn, 401)
    end
  end

  describe "get stream by ID with registered CLI" do
    setup [:register_cli, :authenticate]

    test "responds with stream info when a stream is found", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user)
      insert(:stream, user: cli.user, public_token: "foobar", producer_token: "bazqux")

      conn = get(conn, ~p"/api/v1/user/streams/foobar")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end

    test "responds with stream info when a stream is found by token prefix", %{
      conn: conn,
      cli: cli
    } do
      insert(:stream, user: cli.user, public_token: "foobar", producer_token: "bazqux")

      conn = get(conn, ~p"/api/v1/user/streams/foo")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end

    @tag user: [streaming_enabled: false]
    test "responds with 403 when user has streaming disabled", %{conn: conn, cli: cli} do
      stream = insert(:stream, user: cli.user, public_token: "foobar")

      conn = get(conn, ~p"/api/v1/user/streams/#{stream}")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    test "responds with 404 when stream is not found", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/user/streams/x")

      assert %{} = json_response(conn, 404)
    end

    test "responds with 404 when stream belongs to another user", %{conn: conn} do
      stream = insert(:stream)

      conn = get(conn, ~p"/api/v1/user/streams/#{stream}")

      assert %{} = json_response(conn, 404)
    end
  end

  describe "get stream by ID via legacy path" do
    setup [:register_cli, :authenticate]

    test "responds with stream info", %{conn: conn, cli: cli} do
      insert(:stream, user: cli.user)
      insert(:stream, user: cli.user, public_token: "foobar", producer_token: "bazqux")

      conn = get(conn, ~p"/api/v1/user/streams/foobar")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end
  end

  describe "update without authentication" do
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = put(conn, ~p"/api/v1/streams/#{stream}", %{"title" => "New title"})

      assert response(conn, 401)
    end
  end

  describe "update with invalid install ID" do
    setup [:authenticate]

    @tag token: "invalid-lol"
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = put(conn, ~p"/api/v1/streams/#{stream}", %{"title" => "New title"})

      assert response(conn, 401)
    end
  end

  describe "update with revoked install ID" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = put(conn, ~p"/api/v1/streams/#{stream}", %{"title" => "New title"})

      assert response(conn, 401)
    end
  end

  describe "update with unregistered CLI" do
    setup [:authenticate]

    @tag user: [email: nil]
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = put(conn, ~p"/api/v1/streams/#{stream}", %{"title" => "New title"})

      assert response(conn, 401)
    end
  end

  describe "update with registered CLI" do
    setup [:register_cli, :authenticate]

    test "succeeds when attrs are valid", %{conn: conn, cli: cli} do
      stream =
        insert(:stream,
          user: cli.user,
          public_token: "foobar",
          producer_token: "bazqux",
          title: "Original title",
          description: "Original description"
        )

      conn =
        put(conn, ~p"/api/v1/streams/#{stream}", %{
          "title" => "New title",
          "description" => "New description"
        })

      assert %{
               "id" => _,
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux",
               "title" => "New title",
               "description" => "New description"
             } = json_response(conn, 200)
    end

    test "fails when attrs are not valid", %{conn: conn, cli: cli} do
      stream = insert(:stream, user: cli.user)

      conn = put(conn, ~p"/api/v1/streams/#{stream}", %{"buffer_time" => -1})

      assert json_response(conn, 422)["errors"]["buffer_time"] != nil
    end

    @tag user: [streaming_enabled: false]
    test "fails when streaming is disabled", %{conn: conn, cli: cli} do
      stream = insert(:stream, user: cli.user)

      conn = put(conn, ~p"/api/v1/streams/#{stream}", %{"title" => "New title"})

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    test "fails when stream is not found", %{conn: conn} do
      conn = put(conn, ~p"/api/v1/streams/99999", %{"title" => "New title"})

      assert json_response(conn, 404)["error"] == "stream not found"
    end
  end

  describe "delete without authentication" do
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/api/v1/streams/#{stream}")

      assert response(conn, 401)
    end
  end

  describe "delete with invalid install ID" do
    setup [:authenticate]

    @tag token: "invalid-lol"
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/api/v1/streams/#{stream}")

      assert response(conn, 401)
    end
  end

  describe "delete with revoked install ID" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/api/v1/streams/#{stream}")

      assert response(conn, 401)
    end
  end

  describe "delete with unregistered CLI" do
    setup [:authenticate]

    @tag user: [email: nil]
    test "fails", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/api/v1/streams/#{stream}")

      assert response(conn, 401)
    end
  end

  describe "delete with registered CLI" do
    setup [:register_cli, :authenticate]

    test "succeeds when deleting own stream", %{conn: conn, cli: cli} do
      stream = insert(:stream, user: cli.user)

      conn = delete(conn, ~p"/api/v1/streams/#{stream}")

      assert response(conn, 204)
    end

    test "fails when stream belongs to another user", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/api/v1/streams/#{stream}")

      assert json_response(conn, 403)["error"] == "Forbidden"
    end

    @tag user: [streaming_enabled: false]
    test "fails when streaming is disabled", %{conn: conn, cli: cli} do
      stream = insert(:stream, user: cli.user)

      conn = delete(conn, ~p"/api/v1/streams/#{stream}")

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
