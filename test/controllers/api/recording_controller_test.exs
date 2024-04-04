defmodule Asciinema.Api.RecordingControllerTest do
  use AsciinemaWeb.ConnCase
  alias Asciinema.Accounts

  setup %{conn: conn} = context do
    token = Map.get(context, :token, "9da34ff4-9bf7-45d4-aa88-98c933b15a3f")

    conn =
      if token do
        put_req_header(conn, "authorization", "Basic " <> Base.encode64("test:" <> token))
      else
        conn
      end

    {:ok, conn: conn, token: token}
  end

  defp upload(conn, upload) do
    post conn, ~p"/api/asciicasts", %{"asciicast" => upload}
  end

  @recording_url ~r|^http://localhost:4001/a/[a-zA-Z0-9]{25}|
  @successful_response ~r|View.+at.+http://localhost:4001/a/[a-zA-Z0-9]{25}\n|s

  describe ".create" do
    test "json file, v1 format", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/asciicast.json"})
      conn = upload(conn, upload)
      assert text_response(conn, 201) =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end

    test "json file, v2 format, minimal", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.cast"})
      conn = upload(conn, upload)
      assert text_response(conn, 201) =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end

    test "json file, v2 format, full", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/full.cast"})
      conn = upload(conn, upload)
      assert text_response(conn, 201) =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end

    test "json file, v1 format, missing required data", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/invalid.json"})
      conn = upload(conn, upload)
      assert %{"errors" => _} = json_response(conn, 422)
    end

    test "json file, v2 format, invalid theme format", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/invalid-theme.cast"})
      conn = upload(conn, upload)
      assert %{"errors" => _} = json_response(conn, 422)
    end

    test "json file, unsupported version number", %{conn: conn} do
      upload = fixture(:upload, %{path: "5/asciicast.json"})
      conn = upload(conn, upload)
      assert text_response(conn, 422) =~ ~r|not supported|
    end

    test "non-json file", %{conn: conn} do
      upload = fixture(:upload, %{path: "new-logo-bars.png"})
      conn = upload(conn, upload)
      assert text_response(conn, 400) =~ ~r|valid asciicast|
    end

    test "existing user (API token)", %{conn: conn, token: token} do
      {:ok, _} = Accounts.create_user_with_api_token(token, "test")
      upload = fixture(:upload, %{path: "1/asciicast.json"})
      conn = upload(conn, upload)
      assert text_response(conn, 201) =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end

    @tag token: nil
    test "no authentication", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/asciicast.json"})
      conn = upload(conn, upload)
      assert response(conn, 401)
    end

    test "authentication with revoked token", %{conn: conn, token: token} do
      # force registration of the token
      Accounts.get_user_with_api_token(token, "test")
      token |> Accounts.get_api_token!() |> Accounts.revoke_api_token!()
      upload = fixture(:upload, %{path: "1/asciicast.json"})
      conn = upload(conn, upload)
      assert response(conn, 401)
    end

    @tag token: "invalid-lol"
    test "authentication with invalid token", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/asciicast.json"})
      conn = upload(conn, upload)
      assert response(conn, 401)
    end

    test "requesting json response", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.cast"})
      conn = put_req_header(conn, "accept", "application/json")
      conn = upload(conn, upload)
      assert %{"url" => "http" <> _} = json_response(conn, 201)
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end
  end
end
