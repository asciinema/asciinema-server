defmodule Asciinema.Api.LiveStreamControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory
  alias Asciinema.Accounts

  @default_install_id "9da34ff4-9bf7-45d4-aa88-98c933b15a3f"

  setup %{conn: conn} = context do
    install_id = Map.get(context, :install_id, @default_install_id)
    mode = Map.get(context, :register, true)

    {:ok, conn: add_auth_header(conn, install_id), user: register_install_id(install_id, mode)}
  end

  describe "get default stream" do
    @tag install_id: nil
    test "responds with 401 when auth missing", %{conn: conn} do
      conn = get(conn, ~p"/api/user/stream")
      assert response(conn, 401)
    end

    @tag register: false
    test "responds with 401 when the install ID is unknown", %{conn: conn} do
      conn = get(conn, ~p"/api/user/stream")
      assert response(conn, 401)
    end

    @tag register: :revoked
    test "responds with 401 when the install ID has been revoked", %{conn: conn} do
      conn = get(conn, ~p"/api/user/stream")
      assert response(conn, 401)
    end

    @tag register: :tmp
    test "responds with 401 when the user has not been verified", %{conn: conn} do
      conn = get(conn, ~p"/api/user/stream")
      assert json_response(conn, 401)
    end

    test "responds with 404 when no stream is available", %{conn: conn} do
      conn = get(conn, ~p"/api/user/stream")
      assert %{} = json_response(conn, 404)
    end

    test "responds with stream info when a stream is available", %{conn: conn, user: user} do
      insert(:live_stream, user: user, public_token: "foobar", producer_token: "bazqux")
      conn = get(conn, ~p"/api/user/stream")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end
  end

  describe "get stream by ID" do
    @tag install_id: nil
    test "responds with 401 when auth missing", %{conn: conn} do
      conn = get(conn, ~p"/api/user/streams/x")
      assert response(conn, 401)
    end

    @tag register: false
    test "responds with 401 when the install ID is unknown", %{conn: conn} do
      conn = get(conn, ~p"/api/user/streams/x")
      assert response(conn, 401)
    end

    @tag register: :revoked
    test "responds with 401 when the install ID has been revoked", %{conn: conn} do
      conn = get(conn, ~p"/api/user/streams/x")
      assert response(conn, 401)
    end

    @tag register: :tmp
    test "responds with 401 when the user has not been verified", %{conn: conn} do
      conn = get(conn, ~p"/api/user/streams/x")
      assert json_response(conn, 401)
    end

    test "responds with 404 when stream is not found", %{conn: conn, user: user} do
      insert(:live_stream, user: user)
      conn = get(conn, ~p"/api/user/streams/x")
      assert %{} = json_response(conn, 404)
    end

    test "responds with 404 when stream belongs to another user", %{conn: conn, user: user} do
      insert(:live_stream, user: user)
      stream = insert(:live_stream)
      conn = get(conn, ~p"/api/user/streams/#{stream}")
      assert %{} = json_response(conn, 404)
    end

    test "responds with stream info when a stream is found", %{conn: conn, user: user} do
      insert(:live_stream, user: user)
      insert(:live_stream, user: user, public_token: "foobar", producer_token: "bazqux")
      conn = get(conn, ~p"/api/user/streams/foobar")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end

    test "responds with stream info when a stream is found by token prefix", %{
      conn: conn,
      user: user
    } do
      insert(:live_stream, user: user, public_token: "foobar", producer_token: "bazqux")
      conn = get(conn, ~p"/api/user/streams/foo")

      assert %{
               "url" => "http://localhost:4001/s/foobar",
               "ws_producer_url" => "ws://localhost:4001/ws/S/bazqux"
             } = json_response(conn, 200)
    end
  end

  defp add_auth_header(conn, nil), do: conn

  defp add_auth_header(conn, install_id) do
    put_req_header(conn, "authorization", "Basic " <> Base.encode64(":" <> install_id))
  end

  defp register_install_id(nil, _mode), do: nil

  defp register_install_id(install_id, mode) do
    case mode do
      false ->
        nil

      :revoked ->
        user = insert(:user)
        {:ok, token} = Accounts.create_api_token(user, install_id)
        Accounts.revoke_api_token!(token)

        user

      :tmp ->
        user = insert(:temporary_user)
        {:ok, _} = Accounts.create_api_token(user, install_id)

        user

      true ->
        user = insert(:user)
        {:ok, _} = Accounts.create_api_token(user, install_id)

        user
    end
  end
end
