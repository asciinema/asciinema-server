defmodule Asciinema.Api.LiveStreamControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  @default_install_id "9da34ff4-9bf7-45d4-aa88-98c933b15a3f"

  describe "create stream" do
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
      conn = add_auth_header(conn, insert(:revoked_api_token))

      conn = post(conn, ~p"/api/streams")

      assert response(conn, 401)
    end

    test "responds with 401 when the user has not been verified", %{conn: conn} do
      conn = add_auth_header(conn, insert(:api_token, user: build(:temporary_user)))

      conn = post(conn, ~p"/api/streams")

      assert json_response(conn, 401)
    end

    test "responds with 404 when no stream is available", %{conn: conn} do
      conn = add_auth_header(conn, insert(:api_token))

      conn = post(conn, ~p"/api/streams")

      assert %{} = json_response(conn, 404)
    end

    test "responds with stream info when a stream is available", %{conn: conn} do
      user = insert(:user)
      insert(:live_stream, user: user, public_token: "foobar", producer_token: "bazqux")
      conn = add_auth_header(conn, insert(:api_token, user: user))

      conn = post(conn, ~p"/api/streams")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end
  end

  describe "get default stream" do
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
      conn = add_auth_header(conn, insert(:revoked_api_token))

      conn = get(conn, ~p"/api/user/stream")

      assert response(conn, 401)
    end

    test "responds with 401 when the user has not been verified", %{conn: conn} do
      conn = add_auth_header(conn, insert(:api_token, user: build(:temporary_user)))

      conn = get(conn, ~p"/api/user/stream")

      assert json_response(conn, 401)
    end

    test "responds with 404 when no stream is available", %{conn: conn} do
      conn = add_auth_header(conn, insert(:api_token))

      conn = get(conn, ~p"/api/user/stream")

      assert %{} = json_response(conn, 404)
    end

    test "responds with stream info when a stream is available", %{conn: conn} do
      user = insert(:user)
      insert(:live_stream, user: user, public_token: "foobar", producer_token: "bazqux")
      conn = add_auth_header(conn, insert(:api_token, user: user))

      conn = get(conn, ~p"/api/user/stream")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end
  end

  describe "get stream by ID" do
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
      conn = add_auth_header(conn, insert(:revoked_api_token))

      conn = get(conn, ~p"/api/user/streams/x")

      assert response(conn, 401)
    end

    test "responds with 401 when the user has not been verified", %{conn: conn} do
      conn = add_auth_header(conn, insert(:api_token, user: build(:temporary_user)))

      conn = get(conn, ~p"/api/user/streams/x")

      assert json_response(conn, 401)
    end

    test "responds with 404 when stream is not found", %{conn: conn} do
      conn = add_auth_header(conn, insert(:api_token))

      conn = get(conn, ~p"/api/user/streams/x")

      assert %{} = json_response(conn, 404)
    end

    test "responds with 404 when stream belongs to another user", %{conn: conn} do
      conn = add_auth_header(conn, insert(:api_token))
      insert(:live_stream, public_token: "foobar")

      conn = get(conn, ~p"/api/user/streams/foobar")

      assert %{} = json_response(conn, 404)
    end

    test "responds with stream info when a stream is found", %{conn: conn} do
      user = insert(:user)
      conn = add_auth_header(conn, insert(:api_token, user: user))
      insert(:live_stream, user: user)
      insert(:live_stream, user: user, public_token: "foobar", producer_token: "bazqux")

      conn = get(conn, ~p"/api/user/streams/foobar")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end

    test "responds with stream info when a stream is found by token prefix", %{conn: conn} do
      user = insert(:user)
      conn = add_auth_header(conn, insert(:api_token, user: user))
      insert(:live_stream, user: user, public_token: "foobar", producer_token: "bazqux")

      conn = get(conn, ~p"/api/user/streams/foo")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end
  end

  defp add_auth_header(conn, %{token: token}) do
    add_auth_header(conn, token)
  end

  defp add_auth_header(conn, install_id) do
    put_req_header(conn, "authorization", "Basic " <> Base.encode64(":" <> install_id))
  end
end
