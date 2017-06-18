defmodule Asciinema.Api.AsciicastControllerTest do
  use Asciinema.ConnCase
  alias Asciinema.Users

  setup %{conn: conn} = context do
    token = Map.get(context, :token, "9da34ff4-9bf7-45d4-aa88-98c933b15a3f")

    conn = if token do
      put_req_header(conn, "authorization", "Basic " <> Base.encode64("test:" <> token))
    else
      conn
    end

    {:ok, conn: conn, token: token}
  end

  @asciicast_url ~r|^http://localhost:4001/a/[a-zA-Z0-9]{25}|

  describe ".create" do
    @tag token: nil
    test "separate files (pre-v1 params), v0.9.7 client", %{conn: conn} do
      asciicast = %{"meta" => fixture(:upload, %{path: "0.9.7/meta.json",
                                                 content_type: "application/json"}),
                    "stdout" => fixture(:upload, %{path: "0.9.7/stdout",
                                                   content_type: "application/octet-stream"}),
                    "stdout_timing" => fixture(:upload, %{path: "0.9.7/stdout.time",
                                                          content_type: "application/octet-stream"})}

      conn = post conn, api_asciicast_path(conn, :create), %{"asciicast" => asciicast}
      assert text_response(conn, 201) =~ @asciicast_url
      assert List.first(get_resp_header(conn, "location")) =~ @asciicast_url
    end

    @tag token: nil
    test "separate files (pre-v1 params), v0.9.8 client", %{conn: conn} do
      asciicast = %{"meta" => fixture(:upload, %{path: "0.9.8/meta.json",
                                                 content_type: "application/json"}),
                    "stdout" => fixture(:upload, %{path: "0.9.8/stdout",
                                                   content_type: "application/octet-stream"}),
                    "stdout_timing" => fixture(:upload, %{path: "0.9.8/stdout.time",
                                                          content_type: "application/octet-stream"})}

      conn = post conn, api_asciicast_path(conn, :create), %{"asciicast" => asciicast}
      assert text_response(conn, 201) =~ @asciicast_url
      assert List.first(get_resp_header(conn, "location")) =~ @asciicast_url
    end

    test "separate files (pre-v1 params), v0.9.9 client", %{conn: conn} do
      asciicast = %{"meta" => fixture(:upload, %{path: "0.9.9/meta.json",
                                                 content_type: "application/json"}),
                    "stdout" => fixture(:upload, %{path: "0.9.9/stdout",
                                                   content_type: "application/octet-stream"}),
                    "stdout_timing" => fixture(:upload, %{path: "0.9.9/stdout.time",
                                                          content_type: "application/octet-stream"})}

      conn = post conn, api_asciicast_path(conn, :create), %{"asciicast" => asciicast}
      assert text_response(conn, 201) =~ @asciicast_url
      assert List.first(get_resp_header(conn, "location")) =~ @asciicast_url
    end

    test "json file, v1 format", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/asciicast.json"})
      conn = post conn, api_asciicast_path(conn, :create), %{"asciicast" => upload}
      assert text_response(conn, 201) =~ @asciicast_url
      assert List.first(get_resp_header(conn, "location")) =~ @asciicast_url
    end

    test "json file, v1 format (missing required data)", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/invalid.json"})
      conn = post conn, api_asciicast_path(conn, :create), %{"asciicast" => upload}
      assert %{"errors" => _} = json_response(conn, 422)
    end

    test "json file, unsupported version number", %{conn: conn} do
      upload = fixture(:upload, %{path: "5/asciicast.json"})
      conn = post conn, api_asciicast_path(conn, :create), %{"asciicast" => upload}
      assert text_response(conn, 415) =~ ~r|not supported|
    end

    test "non-json file", %{conn: conn} do
      upload = fixture(:upload, %{path: "new-logo-bars.png"})
      conn = post conn, api_asciicast_path(conn, :create), %{"asciicast" => upload}
      assert text_response(conn, 400) =~ ~r|valid asciicast|
    end

    test "existing user (API token)", %{conn: conn, token: token} do
      Users.create_user_with_api_token("test", token)
      upload = fixture(:upload, %{path: "1/asciicast.json"})
      conn = post conn, api_asciicast_path(conn, :create), %{"asciicast" => upload}
      assert text_response(conn, 201) =~ @asciicast_url
      assert List.first(get_resp_header(conn, "location")) =~ @asciicast_url
    end

    @tag token: nil
    test "no authentication", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/asciicast.json"})
      conn = post conn, api_asciicast_path(conn, :create), %{"asciicast" => upload}
      assert response(conn, 401)
    end

    test "authentication with revoked token", %{conn: conn, token: token} do
      Users.get_user_with_api_token("test", token) # force registration of the token
      token |> Users.get_api_token! |> Users.revoke_api_token!
      upload = fixture(:upload, %{path: "1/asciicast.json"})
      conn = post conn, api_asciicast_path(conn, :create), %{"asciicast" => upload}
      assert response(conn, 401)
    end

    @tag token: "invalid-lol"
    test "authentication with invalid token", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/asciicast.json"})
      conn = post conn, api_asciicast_path(conn, :create), %{"asciicast" => upload}
      assert response(conn, 401)
    end
  end
end
