defmodule AsciinemaWeb.Api.RecordingControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory
  alias Asciinema.Accounts

  setup(context) do
    [token: Map.get(context, :token, "9da34ff4-9bf7-45d4-aa88-98c933b15a3f")]
  end

  @recording_url ~r|^http://localhost:4001/a/[a-zA-Z0-9]{25}|
  @successful_response ~r|View.+at.+http://localhost:4001/a/[a-zA-Z0-9]{25}\n|s

  describe "create without authentication" do
    test "fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "3/minimal.cast"})

      conn = upload(conn, upload)

      assert json_response(conn, 401)["error"] == "Missing install ID"
    end
  end

  describe "create with invalid install ID" do
    setup [:authenticate]

    @tag token: "invalid-lol"
    test "fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "3/minimal.cast"})

      conn = upload(conn, upload)

      assert json_response(conn, 401)["error"] == "Invalid install ID"
    end
  end

  describe "create with revoked install ID" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "3/minimal.json"})

      conn = upload(conn, upload)

      assert json_response(conn, 401)["error"] == "Revoked install ID"
    end
  end

  describe "create with authentication" do
    setup [:authenticate]

    test "json file, v1 format succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/full.json"})

      conn = upload(conn, upload)
      response = json_response(conn, 201)

      assert response["url"] =~ @recording_url
      assert response["message"] =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end

    test "json file, v2 format, minimal succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.cast"})

      conn = upload(conn, upload)
      response = json_response(conn, 201)

      assert response["url"] =~ @recording_url
      assert response["message"] =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end

    test "json file, v2 format, full succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/full.cast"})

      conn = upload(conn, upload)
      response = json_response(conn, 201)

      assert response["url"] =~ @recording_url
      assert response["message"] =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end

    test "json file, v1 format, missing required data fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/invalid.json"})

      conn = upload(conn, upload)

      assert %{"errors" => _} = json_response(conn, 422)
    end

    test "json file, v2 format, invalid theme format fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/invalid-theme.cast"})

      conn = upload(conn, upload)

      assert %{"errors" => _} = json_response(conn, 422)
    end

    test "json file, unsupported version number fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "5/asciicast.json"})

      conn = upload(conn, upload)

      assert json_response(conn, 422)["error"] =~ ~r|not supported|
    end

    test "non-json file fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "favicon.png"})

      conn = upload(conn, upload)

      assert json_response(conn, 400)["error"] =~ ~r|valid asciicast|
    end

    test "requesting json response succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.cast"})
      conn = put_req_header(conn, "accept", "application/json")

      conn = upload(conn, upload)

      assert %{"url" => "http" <> _} = json_response(conn, 201)
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end
  end

  describe "create with registered cli when registration is not required" do
    setup [:register_cli, :authenticate]

    test "succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/full.json"})

      conn = upload(conn, upload)
      response = json_response(conn, 201)

      assert response["url"] =~ @recording_url
      assert response["message"] =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end
  end

  describe "create with registered cli when registration is required" do
    setup [:require_registered_cli, :register_cli, :authenticate]

    test "succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.cast"})

      conn = upload(conn, upload)
      response = json_response(conn, 201)

      assert response["url"] =~ @recording_url
      assert response["message"] =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end
  end

  describe "create with non-registered cli when registration is required" do
    setup [:require_registered_cli, :authenticate]

    @tag user: [email: nil]
    test "fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.cast"})

      conn = upload(conn, upload)

      assert json_response(conn, 401)["error"] == "Unregistered install ID"
    end
  end

  defp upload(conn, upload) do
    conn
    |> put_resp_content_type("application/json")
    |> post(~p"/api/asciicasts", %{"asciicast" => upload})
  end

  defp require_registered_cli(_context) do
    on_exit_restore_config(Asciinema.Accounts)
    Application.put_env(:asciinema, Asciinema.Accounts, upload_auth_required: true)
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
        put_req_header(conn, "authorization", "Basic " <> Base.encode64("test:" <> token))
      else
        conn
      end

    [conn: conn]
  end
end
