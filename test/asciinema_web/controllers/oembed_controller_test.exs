defmodule AsciinemaWeb.OembedControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory

  describe "dimension validation" do
    setup do
      recording = insert(:asciicast, term_cols: 200, term_rows: 10)
      portrait_recording = insert(:asciicast, term_cols: 10, term_rows: 100)
      stream = insert(:stream)
      %{urls: [~p"/a/#{recording}", ~p"/a/#{portrait_recording}", ~p"/s/#{stream}"]}
    end

    test "rejects invalid dimensions for JSON and XML requests", %{conn: conn, urls: urls} do
      for url <- urls,
          {format, accept} <- [{"json", "application/json"}, {"xml", "application/xml"}],
          key <- [:maxwidth, :maxheight],
          value <- ["", "abc", "100px", "1.5", "0", "-1", ["100"], %{value: "100"}] do
        params = Map.put(%{url: url, format: format}, key, value)

        conn = conn |> put_req_header("accept", accept) |> get(~p"/oembed?#{params}")

        assert response(conn, 400)
      end
    end

    test "accepts omitted and positive dimensions", %{conn: conn, urls: urls} do
      for url <- urls,
          limits <- [
            %{},
            %{maxwidth: 300},
            %{maxheight: 100},
            %{maxwidth: 300, maxheight: 100},
            %{maxwidth: 1},
            %{maxheight: 1}
          ] do
        params = Map.merge(%{url: url, format: "json"}, limits)
        data = conn |> get(~p"/oembed?#{params}") |> json_response(200)

        assert data["width"] > 0
        assert data["height"] > 0
        if limits[:maxwidth], do: assert(data["width"] <= limits.maxwidth)
        if limits[:maxheight], do: assert(data["height"] <= limits.maxheight)
      end
    end

    test "tiny limits keep both output dimensions at least one pixel", %{conn: conn, urls: urls} do
      for url <- urls, format <- ["json", "xml"] do
        params = %{url: url, format: format, maxwidth: 1, maxheight: 1}
        conn = get(conn, ~p"/oembed?#{params}")

        case format do
          "json" ->
            data = json_response(conn, 200)
            assert data["width"] == 1
            assert data["height"] == 1

          "xml" ->
            xml = response(conn, 200)
            assert response_content_type(conn, :xml)
            assert xml =~ ~s(<width type="integer">1</width>)
            assert xml =~ ~s(<height type="integer">1</height>)
        end
      end
    end

    test "very large limits use the original dimensions", %{conn: conn} do
      stream = insert(:stream)
      huge = String.duplicate("9", 400)
      params = %{url: ~p"/s/#{stream}", maxwidth: huge, maxheight: huge}

      data = conn |> get(~p"/oembed?#{params}") |> json_response(200)

      assert data["width"] == 640
      assert data["height"] == 400
    end
  end

  describe "show" do
    test "JSON format", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = ~p"/a/#{asciicast}"

      conn =
        get(conn, ~p"/oembed?#{%{url: url, format: "json", maxwidth: "500", maxheight: "300"}}")

      data = json_response(conn, 200)
      assert data["type"] == "rich"
      assert data["html"] =~ "<a "
      assert data["html"] =~ "<img "
      assert data["thumbnail_url"] == AsciinemaWeb.Endpoint.url() <> ~p"/a/#{asciicast}" <> ".png"
      assert data["width"] == data["thumbnail_width"]
      assert data["height"] == data["thumbnail_height"]
      refute data["html"] =~ "<iframe"
    end

    test "XML format", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = ~p"/a/#{asciicast}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "xml"}}")

      assert response(conn, 200)
      assert response_content_type(conn, :xml)
      assert response(conn, 200) =~ "<thumbnail-url>"
    end

    test "maxwidth without maxheight", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = ~p"/a/#{asciicast}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "json", maxwidth: "500"}}")

      assert json_response(conn, 200)
    end

    test "private recording via secret token", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :private)
      url = ~p"/a/#{asciicast.secret_token}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "json"}}")

      assert json_response(conn, 403)
    end

    test "private recording via ID", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :private)
      url = ~p"/a/#{asciicast.id}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "json"}}")

      assert json_response(conn, 404)
    end

    test "unlisted recording via secret token", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :unlisted)
      url = ~p"/a/#{asciicast.secret_token}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "json"}}")

      assert json_response(conn, 200)
    end

    test "unlisted recording via ID", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :unlisted)
      url = ~p"/a/#{asciicast.id}"

      conn = get(conn, ~p"/oembed?#{%{url: url, format: "json"}}")

      assert json_response(conn, 404)
    end

    test "bad request", %{conn: conn} do
      conn = get(conn, ~p"/oembed?#{%{url: "", format: "json"}}")

      assert json_response(conn, 400)
    end
  end

  describe "stream oEmbed" do
    test "JSON embeds public and unlisted streams whether live or offline", %{conn: conn} do
      for visibility <- [:public, :unlisted], live <- [true, false] do
        stream = insert(:stream, visibility: visibility, live: live, title: "Live terminal")
        url = AsciinemaWeb.Endpoint.url() <> ~p"/s/#{stream}"
        conn = get(conn, ~p"/oembed?#{%{url: url, format: "json"}}")
        data = json_response(conn, 200)

        assert data["type"] == "rich"
        assert data["version"] == 1.0
        assert data["title"] == stream.title
        assert data["author_name"] == stream.user.username
        assert data["author_url"] == AsciinemaWeb.Endpoint.url() <> ~p"/~#{stream.user}"
        assert data["provider_name"] == "asciinema"
        assert data["provider_url"] == AsciinemaWeb.Endpoint.url() <> "/"
        assert data["width"] == 640
        assert data["height"] == 400
        assert data["html"] =~ "<iframe"
        assert data["html"] =~ ~s(src="#{url}/iframe")
        assert data["html"] =~ ~s(title="Live terminal")
        assert data["html"] =~ ~s(width="640")
        assert data["html"] =~ ~s(height="400")
        assert data["html"] =~ "allowfullscreen"
        refute data["html"] =~ stream.producer_token
        refute Map.has_key?(data, "thumbnail_url")
        refute Map.has_key?(data, "thumbnail_width")
        refute Map.has_key?(data, "thumbnail_height")
      end
    end

    test "XML returns escaped iframe HTML without thumbnails", %{conn: conn} do
      stream = insert(:stream)
      url = ~p"/s/#{stream}"
      conn = get(conn, ~p"/oembed?#{%{url: url, format: "xml", maxwidth: 320}}")
      xml = response(conn, 200)

      assert response_content_type(conn, :xml)
      assert xml =~ "&lt;iframe"
      assert xml =~ "/s/#{stream.public_token}/iframe"
      assert xml =~ ~s(<width type="integer">320</width>)
      assert xml =~ ~s(<height type="integer">200</height>)
      refute xml =~ "<thumbnail-"
    end

    test "respects width and height limits", %{conn: conn} do
      stream = insert(:stream)
      url = ~p"/s/#{stream}"

      for {limits, width, height} <- [
            {%{maxwidth: 320}, 320, 200},
            {%{maxheight: 100}, 160, 100},
            {%{maxwidth: 300, maxheight: 100}, 160, 100},
            {%{maxwidth: 1000, maxheight: 1000}, 640, 400}
          ] do
        params = Map.merge(%{url: url, format: "json"}, limits)
        data = conn |> get(~p"/oembed?#{params}") |> json_response(200)

        assert data["width"] == width
        assert data["height"] == height
        assert data["html"] =~ ~s(width="#{width}")
        assert data["html"] =~ ~s(height="#{height}")
      end
    end

    test "uses the fallback stream title", %{conn: conn} do
      stream = insert(:stream, title: nil)
      params = %{url: ~p"/s/#{stream}", format: "json"}
      data = conn |> get(~p"/oembed?#{params}") |> json_response(200)

      assert data["title"] == "#{stream.user.username}'s stream"
    end

    test "escapes stream titles in iframe HTML", %{conn: conn} do
      stream = insert(:stream, title: ~s|<script>alert("test")</script>|)
      params = %{url: ~p"/s/#{stream}", format: "json"}
      data = conn |> get(~p"/oembed?#{params}") |> json_response(200)

      assert data["title"] == stream.title
      assert data["html"] =~ "&lt;script&gt;"
      assert data["html"] =~ "&quot;test&quot;"
      refute data["html"] =~ "<script>"
    end

    test "rejects private streams even for their owner", %{conn: conn} do
      stream = insert(:stream, visibility: :private)
      params = %{url: ~p"/s/#{stream}", format: "json"}

      assert conn |> get(~p"/oembed?#{params}") |> json_response(403)

      assert conn
             |> log_in(stream.user)
             |> get(~p"/oembed?#{params}")
             |> json_response(403)
    end

    test "rejects missing streams", %{conn: conn} do
      params = %{url: "/s/0123456789abcdef", format: "json"}

      assert conn |> get(~p"/oembed?#{params}") |> json_response(404)
    end

    test "rejects streams with streaming disabled", %{conn: conn} do
      stream = insert(:stream, user: build(:user, streaming_enabled: false))
      params = %{url: ~p"/s/#{stream}", format: "json"}

      assert conn |> get(~p"/oembed?#{params}") |> json_response(404)
    end
  end
end
