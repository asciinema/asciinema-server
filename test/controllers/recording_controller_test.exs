defmodule Asciinema.RecordingControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  describe "explore" do
    test "auto", %{conn: conn} do
      insert(:asciicast, featured: true, title: "Featured stuff")

      conn = get(conn, ~p"/explore")

      html = html_response(conn, 200)
      assert html =~ "Featured stuff"
      refute html =~ "Good stuff"
    end

    test "public", %{conn: conn} do
      insert(:asciicast, private: false, title: "Good stuff")

      conn = get(conn, ~p"/explore/public")

      html = html_response(conn, 200)
      assert html =~ "Good stuff"
      refute html =~ "Featured stuff"
    end

    test "featured", %{conn: conn} do
      insert(:asciicast, featured: true, title: "Featured stuff")

      conn = get(conn, ~p"/explore/featured")

      html = html_response(conn, 200)
      assert html =~ "Featured stuff"
      refute html =~ "Good stuff"
    end
  end

  describe "show" do
    test "HTML", %{conn: conn} do
      asciicast = insert(:asciicast, title: "Good stuff")
      url = ~p"/a/#{asciicast}"

      conn_2 = get(conn, url)

      html = html_response(conn_2, 200)
      assert html =~ "Good stuff"
      assert html =~ "application/json+oembed"
      assert html =~ "application/x-asciicast"

      conn_2 =
        conn
        |> put_req_header("accept", "*/*")
        |> get(url)

      assert html_response(conn_2, 200) =~ "Good stuff"
    end

    test "HTML, public recording via secret token", %{conn: conn} do
      asciicast = insert(:asciicast, private: false)

      conn_2 = get(conn, ~p"/a/#{asciicast.secret_token}")

      assert redirected_to(conn_2, 302) == ~p"/a/#{asciicast.id}"
    end

    test "IFRAME, public recording via secret token", %{conn: conn} do
      asciicast = insert(:asciicast, private: false)

      conn_2 = get(conn, ~p"/a/#{asciicast.secret_token}/iframe")

      assert html_response(conn_2, 200) =~ "createPlayer"
    end

    test "asciicast file, v1 format", %{conn: conn} do
      asciicast = fixture(:asciicast_v1)
      width = asciicast.cols

      conn = get(conn, asciicast_file_path(conn, asciicast))

      assert %{"version" => 1, "width" => ^width, "stdout" => [_ | _]} = json_response(conn, 200)
    end

    test "asciicast file, v2 format", %{conn: conn} do
      asciicast = fixture(:asciicast_v2)

      conn = get(conn, asciicast_file_path(conn, asciicast))

      assert response(conn, 200)
    end

    test "TXT", %{conn: conn} do
      asciicast = insert(:asciicast) |> with_file()
      url = ~p"/a/#{asciicast}"

      conn_2 = get(conn, url <> ".txt")

      assert text_response(conn_2, 200)

      conn_2 =
        conn
        |> put_req_header("accept", "text/plain")
        |> get(url)

      assert text_response(conn_2, 200)
    end

    @tag :rsvg
    test "PNG", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = ~p"/a/#{asciicast}"

      conn_2 = get(conn, url <> ".png")

      assert response(conn_2, 200)
      assert response_content_type(conn_2, :png)

      conn_2 =
        conn
        |> put_req_header("accept", "image/png")
        |> get(url)

      assert response(conn_2, 200)
      assert response_content_type(conn_2, :png)
    end

    test "SVG", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = ~p"/a/#{asciicast}"

      conn_2 = get(conn, url <> ".svg")

      assert response(conn_2, 200)
      assert response_content_type(conn_2, :svg)

      conn_2 =
        conn
        |> put_req_header("accept", "image/svg+xml")
        |> get(url)

      assert response(conn_2, 200)
      assert response_content_type(conn_2, :svg)

      conn_2 =
        conn
        |> put_req_header("accept", "image/*")
        |> get(url)

      assert response(conn_2, 200)
      assert response_content_type(conn_2, :svg)
    end

    test "HTML with GIF generation instructions", %{conn: conn} do
      asciicast = insert(:asciicast)

      conn = get(conn, ~p"/a/#{asciicast}" <> ".gif")

      assert html_response(conn, 200) =~ "GIF"
    end

    test "embed JS", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = ~p"/a/#{asciicast}"

      conn_2 = get(conn, url <> ".js")

      assert response(conn_2, 200)
      assert response_content_type(conn_2, :js)

      conn_2 =
        conn
        |> put_req_header("accept", "application/javascript")
        |> get(url)

      assert response(conn_2, 200)
      assert response_content_type(conn_2, :js)
    end

    test "embed iframe", %{conn: conn} do
      asciicast = fixture(:asciicast)

      conn = get(conn, ~p"/a/#{asciicast}/iframe")

      html = html_response(conn, 200)
      assert html =~ ~r/iframe\.css/
      assert html =~ ~r/iframe\.js/
      assert html =~ ~r/window\.createPlayer/
    end
  end

  describe "editing" do
    setup ctx do
      user = insert(:user)

      Map.merge(ctx, %{
        user: user,
        asciicast: insert(:asciicast, user: user)
      })
    end

    test "requires logged in user", %{conn: conn, asciicast: asciicast} do
      conn = get(conn, ~p"/a/#{asciicast}/edit")

      assert redirected_to(conn, 302) == ~p"/login/new"
    end

    test "requires author", %{conn: conn, asciicast: asciicast} do
      conn = log_in(conn, insert(:user))

      conn = get(conn, ~p"/a/#{asciicast}/edit")

      assert html_response(conn, 403) =~ "access"
    end

    test "displays form", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)

      conn = get(conn, ~p"/a/#{asciicast}/edit")

      assert html_response(conn, 200) =~ "Save"
    end

    test "updates title", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)
      attrs = %{asciicast: %{title: "Haha!"}}

      conn = put conn, ~p"/a/#{asciicast}", attrs

      location = List.first(get_resp_header(conn, "location"))
      assert flash(conn, :info) =~ ~r/updated/i
      assert response(conn, 302)

      conn = get(build_conn(), location)

      assert html_response(conn, 200) =~ "Haha!"
    end
  end

  describe "deleting" do
    setup ctx do
      user = insert(:user)

      Map.merge(ctx, %{
        user: user,
        asciicast: insert(:asciicast, user: user) |> with_file()
      })
    end

    test "requires author", %{conn: conn, asciicast: asciicast} do
      conn = log_in(conn, insert(:user))

      conn = delete(conn, ~p"/a/#{asciicast}")

      assert html_response(conn, 403) =~ "access"
    end

    test "removes and redirects", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/a/#{asciicast}")

      assert flash(conn, :info) =~ ~r/deleted/i
      assert response(conn, 302)

      conn = get(build_conn(), ~p"/a/#{asciicast}")

      assert html_response(conn, 404) =~ ~r/not found/i
    end
  end
end
