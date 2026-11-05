defmodule AsciinemaWeb.StreamControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory

  describe "embed script" do
    test "serves the recording embed script for public and unlisted streams, live or offline", %{
      conn: conn
    } do
      recording = insert(:asciicast)
      recording_conn = get(conn, ~p"/a/#{recording}" <> ".js")
      script = response(recording_conn, 200)

      for visibility <- [:public, :unlisted], live <- [true, false] do
        stream = insert(:stream, visibility: visibility, live: live)
        conn = get(conn, ~p"/s/#{stream}" <> ".js")

        assert response(conn, 200) == script
        assert response_content_type(conn, :js)
        assert get_resp_header(conn, "cache-control") == ["public, max-age=60"]
        assert get_resp_header(conn, "vary") == ["accept"]
        refute script =~ stream.producer_token
      end
    end

    test "supports JavaScript content negotiation", %{conn: conn} do
      stream = insert(:stream)
      conn = conn |> put_req_header("accept", "application/javascript") |> get(~p"/s/#{stream}")

      assert response(conn, 200)
      assert response_content_type(conn, :js)
      assert get_resp_header(conn, "vary") == ["accept"]
    end

    test "requires authorization for private streams", %{conn: conn} do
      stream = insert(:stream, visibility: :private)
      path = ~p"/s/#{stream}" <> ".js"

      assert conn |> get(path) |> text_response(403)
      assert conn |> log_in(insert(:user)) |> get(path) |> text_response(403)

      for user <- [stream.user, insert(:user, is_admin: true)] do
        conn = conn |> log_in(user) |> get(path)
        assert response(conn, 200)
        assert response_content_type(conn, :js)
      end
    end

    test "rejects missing streams", %{conn: conn} do
      assert conn |> get(~p"/s/0123456789abcdef.js") |> text_response(404)
    end

    test "rejects streams with streaming disabled", %{conn: conn} do
      stream = insert(:stream, user: build(:user, streaming_enabled: false))
      assert conn |> get(~p"/s/#{stream}" <> ".js") |> text_response(404)
    end

    test "rejects unsupported formats", %{conn: conn} do
      stream = insert(:stream)

      assert_error_sent 406, fn ->
        get(conn, ~p"/s/#{stream}" <> ".json")
      end
    end

    test "does not enable JavaScript for management routes", %{conn: conn} do
      stream = insert(:stream)
      conn = conn |> log_in(stream.user) |> put_req_header("accept", "application/javascript")

      for {method, path} <- [
            {:get, ~p"/s/#{stream}/edit"},
            {:patch, ~p"/s/#{stream}"},
            {:delete, ~p"/s/#{stream}"}
          ] do
        assert_error_sent 406, fn ->
          dispatch(conn, @endpoint, method, path)
        end
      end

      assert Asciinema.Streaming.get_stream(stream.id)
    end
  end

  describe "iframe" do
    test "embeds public and unlisted streams whether live or offline", %{conn: conn} do
      for visibility <- [:public, :unlisted], live <- [true, false] do
        stream = insert(:stream, visibility: visibility, live: live)
        conn = get(conn, ~p"/s/#{stream}/iframe")
        html = html_response(conn, 200)

        assert html =~ "createIframePlayer"
        assert html =~ "/ws/s/#{stream.public_token}"
        assert html =~ "/assets/iframe.js"
        assert html =~ "/assets/iframe.css"
        assert html =~ ~s("autoplay":true)
        refute html =~ stream.producer_token
        assert get_resp_header(conn, "x-frame-options") == []
        assert get_resp_header(conn, "content-security-policy") == ["base-uri 'self'"]
      end
    end

    test "uses stream player options", %{conn: conn} do
      stream = insert(:stream, audio_url: "https://example.com/audio")
      conn = get(conn, ~p"/s/#{stream}/iframe?#{%{theme: "monokai", cols: 100}}")
      html = html_response(conn, 200)

      assert html =~ ~s("theme":"monokai")
      assert html =~ ~s("cols":100)
      assert html =~ ~s("rows":24)
      assert html =~ ~s("autoplay":false)
      assert html =~ ~s("audioUrl":"https://example.com/audio")
    end

    test "requires authorization for private streams", %{conn: conn} do
      stream = insert(:stream, visibility: :private)

      assert conn |> get(~p"/s/#{stream}/iframe") |> html_response(403)

      assert conn
             |> log_in(stream.user)
             |> get(~p"/s/#{stream}/iframe")
             |> html_response(200)
    end

    test "rejects missing streams", %{conn: conn} do
      assert conn |> get(~p"/s/0123456789abcdef/iframe") |> html_response(404)
    end

    test "rejects streams with streaming disabled", %{conn: conn} do
      stream = insert(:stream, user: build(:user, streaming_enabled: false))

      assert conn |> get(~p"/s/#{stream}/iframe") |> html_response(404)
    end
  end

  describe "show" do
    test "HTML responses vary by Accept", %{conn: conn} do
      stream = insert(:stream)
      conn = conn |> put_req_header("accept", "text/html") |> get(~p"/s/#{stream}")

      assert html_response(conn, 200)
      assert get_resp_header(conn, "vary") == ["accept"]
    end

    test "advertises oEmbed without allowing framing of the normal page", %{conn: conn} do
      stream = insert(:stream)
      conn = get(conn, ~p"/s/#{stream}")
      html = html_response(conn, 200)

      assert html =~ ~s(type="application/json+oembed")
      assert html =~ ~s(type="text/xml+oembed")
      assert html =~ "format=json&amp;url="
      assert html =~ "format=xml&amp;url="
      assert html =~ URI.encode_www_form(AsciinemaWeb.Endpoint.url() <> ~p"/s/#{stream}")
      assert html =~ ~s(name="robots" content="noindex, nofollow")
      assert html =~ ~s(name="referrer" content="origin")

      assert Enum.any?(get_resp_header(conn, "content-security-policy"), fn policy ->
               policy =~ "frame-ancestors 'self'"
             end)
    end
  end

  describe "deleting" do
    test "requires author", %{conn: conn} do
      user = insert(:user)
      stream = insert(:stream, user: user)
      conn = log_in(conn, insert(:user))

      conn = delete(conn, ~p"/s/#{stream}")

      assert html_response(conn, 403)
    end
  end
end
