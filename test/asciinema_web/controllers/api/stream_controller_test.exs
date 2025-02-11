defmodule AsciinemaWeb.Api.StreamControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  @default_install_id "9da34ff4-9bf7-45d4-aa88-98c933b15a3f"

  setup do
    on_exit_restore_config(Asciinema.Streaming)

    :ok
  end

  describe "create stream" do
    test "responds with default stream info when a fixed stream is available", %{conn: conn} do
      set_streaming_mode(:fixed)
      user = insert(:user)
      insert(:stream, user: user, public_token: "foobar", producer_token: "bazqux")
      conn = add_auth_header(conn, insert(:cli, user: user))

      conn = post(conn, ~p"/api/streams")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end

    test "responds with dynamic stream info when mode is dynamic", %{conn: conn} do
      set_streaming_mode(:dynamic)
      user = insert(:user)
      conn = add_auth_header(conn, insert(:cli, user: user))

      conn = post(conn, ~p"/api/streams")

      assert %{
               "url" => "http://localhost:4001/s/" <> _,
               "ws_producer_url" => "ws://localhost:4001/ws/S/" <> _
             } = json_response(conn, 200)
    end

    test "responds with 401 when auth missing", %{conn: conn} do
      conn = post(conn, ~p"/api/streams")

      assert response(conn, 401)
    end

    test "responds with 401 when the install ID is unknown", %{conn: conn} do
      conn = add_auth_header(conn, @default_install_id)

      conn = post(conn, ~p"/api/streams")

      assert response(conn, 401)
    end

    test "responds with 401 when the install ID has been revoked", %{conn: conn} do
      conn = add_auth_header(conn, insert(:revoked_cli))

      conn = post(conn, ~p"/api/streams")

      assert response(conn, 401)
    end

    test "responds with 401 when the user has not been verified", %{conn: conn} do
      conn = add_auth_header(conn, insert(:cli, user: build(:temporary_user)))

      conn = post(conn, ~p"/api/streams")

      assert json_response(conn, 401)
    end

    test "responds with 403 when user has streaming disabled", %{conn: conn} do
      user = insert(:user, streaming_enabled: false)
      insert(:stream, user: user)
      conn = add_auth_header(conn, insert(:cli, user: user))

      conn = post(conn, ~p"/api/streams")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    test "responds with 403 when streaming is disabled system-wide", %{conn: conn} do
      set_streaming_mode(:disabled)
      user = insert(:user)
      conn = add_auth_header(conn, insert(:cli, user: user))

      conn = post(conn, ~p"/api/streams")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    test "responds with 404 when no stream is available in fixed mode", %{conn: conn} do
      set_streaming_mode(:fixed)
      conn = add_auth_header(conn, insert(:cli))

      conn = post(conn, ~p"/api/streams")

      assert %{} = json_response(conn, 404)
    end

    test "responds with 422 when more than one fixed stream is available", %{conn: conn} do
      set_streaming_mode(:fixed)
      user = insert(:user)
      insert_list(2, :stream, user: user)
      conn = add_auth_header(conn, insert(:cli, user: user))

      conn = post(conn, ~p"/api/streams")

      assert %{"reason" => "no default stream found"} = json_response(conn, 422)
    end
  end

  describe "get default stream" do
    test "responds with stream info when a stream is available", %{conn: conn} do
      user = insert(:user)
      insert(:stream, user: user, public_token: "foobar", producer_token: "bazqux")
      conn = add_auth_header(conn, insert(:cli, user: user))

      conn = get(conn, ~p"/api/user/stream")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end

    test "responds with 401 when auth missing", %{conn: conn} do
      conn = get(conn, ~p"/api/user/stream")

      assert response(conn, 401)
    end

    test "responds with 401 when the install ID is unknown", %{conn: conn} do
      conn = add_auth_header(conn, @default_install_id)

      conn = get(conn, ~p"/api/user/stream")

      assert response(conn, 401)
    end

    test "responds with 401 when the install ID has been revoked", %{conn: conn} do
      conn = add_auth_header(conn, insert(:revoked_cli))

      conn = get(conn, ~p"/api/user/stream")

      assert response(conn, 401)
    end

    test "responds with 401 when the user has not been verified", %{conn: conn} do
      conn = add_auth_header(conn, insert(:cli, user: build(:temporary_user)))

      conn = get(conn, ~p"/api/user/stream")

      assert json_response(conn, 401)
    end

    test "responds with 403 when user has streaming disabled", %{conn: conn} do
      user = insert(:user, streaming_enabled: false)
      insert(:stream, user: user)
      conn = add_auth_header(conn, insert(:cli, user: user))

      conn = get(conn, ~p"/api/user/stream")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    test "responds with 403 when streaming is disabled system-wide", %{conn: conn} do
      set_streaming_mode(:disabled)
      user = insert(:user)
      conn = add_auth_header(conn, insert(:cli, user: user))

      conn = get(conn, ~p"/api/user/stream")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    test "responds with 404 when no stream is available", %{conn: conn} do
      conn = add_auth_header(conn, insert(:cli))

      conn = get(conn, ~p"/api/user/stream")

      assert %{} = json_response(conn, 404)
    end

    test "responds with 422 when more than one fixed stream is available", %{conn: conn} do
      set_streaming_mode(:fixed)
      user = insert(:user)
      insert_list(2, :stream, user: user)
      conn = add_auth_header(conn, insert(:cli, user: user))

      conn = get(conn, ~p"/api/user/stream")

      assert %{"reason" => "no default stream found"} = json_response(conn, 422)
    end
  end

  describe "get stream by ID" do
    test "responds with stream info when a stream is found", %{conn: conn} do
      user = insert(:user)
      conn = add_auth_header(conn, insert(:cli, user: user))
      insert(:stream, user: user)
      insert(:stream, user: user, public_token: "foobar", producer_token: "bazqux")

      conn = get(conn, ~p"/api/user/streams/foobar")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end

    test "responds with stream info when a stream is found by token prefix", %{conn: conn} do
      user = insert(:user)
      conn = add_auth_header(conn, insert(:cli, user: user))
      insert(:stream, user: user, public_token: "foobar", producer_token: "bazqux")

      conn = get(conn, ~p"/api/user/streams/foo")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end

    test "responds with 401 when auth missing", %{conn: conn} do
      conn = get(conn, ~p"/api/user/streams/x")

      assert response(conn, 401)
    end

    test "responds with 401 when the install ID is unknown", %{conn: conn} do
      conn = add_auth_header(conn, @default_install_id)

      conn = get(conn, ~p"/api/user/streams/x")

      assert response(conn, 401)
    end

    test "responds with 401 when the install ID has been revoked", %{conn: conn} do
      conn = add_auth_header(conn, insert(:revoked_cli))

      conn = get(conn, ~p"/api/user/streams/x")

      assert response(conn, 401)
    end

    test "responds with 401 when the user has not been verified", %{conn: conn} do
      conn = add_auth_header(conn, insert(:cli, user: build(:temporary_user)))

      conn = get(conn, ~p"/api/user/streams/x")

      assert json_response(conn, 401)
    end

    test "responds with 403 when user has streaming disabled", %{conn: conn} do
      user = insert(:user, streaming_enabled: false)
      insert(:stream, user: user)
      conn = add_auth_header(conn, insert(:cli, user: user))

      conn = get(conn, ~p"/api/user/streams/x")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    test "responds with 403 when streaming is disabled system-wide", %{conn: conn} do
      set_streaming_mode(:disabled)
      user = insert(:user)
      conn = add_auth_header(conn, insert(:cli, user: user))

      conn = get(conn, ~p"/api/user/streams/x")

      assert %{"reason" => "streaming disabled"} = json_response(conn, 403)
    end

    test "responds with 404 when stream is not found", %{conn: conn} do
      conn = add_auth_header(conn, insert(:cli))

      conn = get(conn, ~p"/api/user/streams/x")

      assert %{} = json_response(conn, 404)
    end

    test "responds with 404 when stream belongs to another user", %{conn: conn} do
      conn = add_auth_header(conn, insert(:cli))
      insert(:stream, public_token: "foobar")

      conn = get(conn, ~p"/api/user/streams/foobar")

      assert %{} = json_response(conn, 404)
    end
  end

  defp add_auth_header(conn, %{token: token}) do
    add_auth_header(conn, token)
  end

  defp add_auth_header(conn, install_id) do
    put_req_header(conn, "authorization", "Basic " <> Base.encode64(":" <> install_id))
  end

  defp set_streaming_mode(mode) do
    Application.put_env(:asciinema, Asciinema.Streaming, mode: mode)
  end
end
