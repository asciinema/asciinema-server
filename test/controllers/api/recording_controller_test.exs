defmodule AsciinemaWeb.Api.RecordingControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory
  alias Asciinema.Accounts

  setup %{conn: conn} = context do
    token = Map.get(context, :token, "9da34ff4-9bf7-45d4-aa88-98c933b15a3f")

    conn =
      if token do
        put_req_header(conn, "authorization", "Basic " <> Base.encode64("test:" <> token))
      else
        conn
      end

    on_exit_restore_config(Asciinema.Accounts)

    {:ok, conn: conn, token: token}
  end

  defp upload(conn, upload) do
    post conn, ~p"/api/asciicasts", %{"asciicast" => upload}
  end

  @recording_url ~r|^http://localhost:4001/a/[a-zA-Z0-9]{25}|
  @successful_response ~r|View.+at.+http://localhost:4001/a/[a-zA-Z0-9]{25}\n|s

  describe "create" do
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

    test "authenticated user when auth is not required", %{conn: conn, token: token} do
      insert(:cli, token: token)
      upload = fixture(:upload, %{path: "1/asciicast.json"})

      conn = upload(conn, upload)

      assert text_response(conn, 201) =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end

    test "authenticated user when auth is required", %{conn: conn, token: token} do
      require_upload_auth()
      insert(:cli, token: token)
      upload = fixture(:upload, %{path: "2/minimal.cast"})

      conn = upload(conn, upload)

      assert text_response(conn, 201) =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end

    test "anonymous user when auth is required", %{conn: conn} do
      require_upload_auth()
      upload = fixture(:upload, %{path: "2/minimal.cast"})

      conn = upload(conn, upload)

      assert text_response(conn, 401) == "Unregistered install ID"
    end

    @tag token: nil
    test "no authentication", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/asciicast.json"})

      conn = upload(conn, upload)

      assert text_response(conn, 401) == "Missing install ID"
    end

    test "authentication with revoked token", %{conn: conn, token: token} do
      insert(:cli, token: token)
      token |> Accounts.get_cli!() |> Accounts.revoke_cli!()
      upload = fixture(:upload, %{path: "1/asciicast.json"})

      conn = upload(conn, upload)

      assert text_response(conn, 401) == "Revoked install ID"
    end

    @tag token: "invalid-lol"
    test "authentication with invalid token", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/asciicast.json"})

      conn = upload(conn, upload)

      assert text_response(conn, 401) == "Invalid install ID"
    end

    test "requesting json response", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.cast"})
      conn = put_req_header(conn, "accept", "application/json")

      conn = upload(conn, upload)

      assert %{"url" => "http" <> _} = json_response(conn, 201)
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end
  end

  defp require_upload_auth do
    Application.put_env(:asciinema, Asciinema.Accounts, upload_auth_required: true)
  end
end
