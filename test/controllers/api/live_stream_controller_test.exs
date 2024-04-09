defmodule Asciinema.Api.LiveStreamControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory
  alias Asciinema.{Accounts, Streaming}

  @default_install_id "9da34ff4-9bf7-45d4-aa88-98c933b15a3f"

  setup %{conn: conn} = context do
    install_id = Map.get(context, :install_id, @default_install_id)
    mode = Map.get(context, :register, true)

    {:ok, conn: add_auth_header(conn, install_id), user: register_install_id(install_id, mode)}
  end

  describe "get default stream" do
    @tag install_id: nil
    test "responds with 401 when auth missing", %{conn: conn} do
      conn = get(conn, ~p"/api/stream")
      assert response(conn, 401)
    end

    @tag register: false
    test "responds with 401 when the install ID is unknown", %{conn: conn} do
      conn = get(conn, ~p"/api/stream")
      assert response(conn, 401)
    end

    @tag register: :revoked
    test "responds with 401 when the install ID has been revoked", %{conn: conn} do
      conn = get(conn, ~p"/api/stream")
      assert response(conn, 401)
    end

    @tag register: :tmp
    test "responds with 401 when the user has not been verified", %{conn: conn} do
      conn = get(conn, ~p"/api/stream")
      assert json_response(conn, 401)
    end

    test "responds with 404 when no stream is available", %{conn: conn} do
      conn = get(conn, ~p"/api/stream")
      assert %{} = json_response(conn, 404)
    end

    test "responds with stream info when a stream is available", %{conn: conn, user: user} do
      %{producer_token: producer_token, secret_token: param} = Streaming.create_live_stream!(user)
      conn = get(conn, ~p"/api/stream")

      assert %{
               "url" => "http://localhost:4001/s/" <> ^param,
               "ws_producer_url" => "ws://localhost:4001/ws/S/" <> ^producer_token
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
