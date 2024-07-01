defmodule Asciinema.RecordingControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  describe "explore" do
    setup do
      insert(:asciicast, visibility: :public, featured: true, title: "Featured stuff")
      insert(:asciicast, visibility: :public, title: "Good stuff")

      :ok
    end

    test "auto", %{conn: conn} do
      conn = get(conn, ~p"/explore")

      html = html_response(conn, 200)
      assert html =~ "Featured stuff"
      refute html =~ "Good stuff"
    end

    test "public", %{conn: conn} do
      conn = get(conn, ~p"/explore/public")

      html = html_response(conn, 200)
      assert html =~ "Good stuff"
      assert html =~ "Featured stuff"
    end

    test "featured", %{conn: conn} do
      conn = get(conn, ~p"/explore/featured")

      html = html_response(conn, 200)
      assert html =~ "Featured stuff"
      refute html =~ "Good stuff"
    end
  end

  describe "show" do
    test "HTML", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = ~p"/a/#{asciicast}"

      conn_2 =
        conn
        |> put_req_header("accept", "*/*")
        |> get(url)

      html = html_response(conn_2, 200)
      assert html =~ "createPlayer"
      assert html =~ "application/json+oembed"
      assert html =~ "application/x-asciicast"

      conn_2 =
        conn
        |> put_req_header("accept", "text/html")
        |> get(url)

      assert html_response(conn_2, 200) =~ "createPlayer"
    end

    test "HTML, public recording", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :public)

      conn_2 = get(conn, ~p"/a/#{asciicast}")

      assert html_response(conn_2, 200) =~ "createPlayer"
    end

    test "HTML, unlisted recording", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :unlisted)

      conn_2 = get(conn, ~p"/a/#{asciicast}")

      assert html_response(conn_2, 200) =~ "createPlayer"
    end

    test "HTML, private recording, unauthenticated", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :private)

      conn_2 = get(conn, ~p"/a/#{asciicast}")

      assert redirected_to(conn_2, 302) == ~p"/login/new"
    end

    test "HTML, private recording, as non-owner", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :private)
      user = insert(:user)
      conn = log_in(conn, user)

      conn_2 = get(conn, ~p"/a/#{asciicast}")

      assert html_response(conn_2, 403)
    end

    test "HTML, private recording, as owner", %{conn: conn} do
      user = insert(:user)
      asciicast = insert(:asciicast, visibility: :private, user: user)
      conn = log_in(conn, user)

      conn_2 = get(conn, ~p"/a/#{asciicast}")

      assert html_response(conn_2, 200) =~ "createPlayer"
    end

    test "HTML, public recording via secret token", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :public)

      conn_2 = get(conn, ~p"/a/#{asciicast.secret_token}")

      assert redirected_to(conn_2, 302) == ~p"/a/#{asciicast.id}"
    end

    test "asciicast file, v1 format", %{conn: conn} do
      asciicast = fixture(:asciicast_v1)
      width = asciicast.cols
      url = ~p"/a/#{asciicast}"

      conn = get(conn, url <> ".json")

      assert %{"version" => 1, "width" => ^width, "stdout" => [_ | _]} = json_response(conn, 200)
    end

    test "asciicast file, v2 format", %{conn: conn} do
      asciicast = fixture(:asciicast_v2)
      url = ~p"/a/#{asciicast}"

      conn = get(conn, url <> ".json")

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

  describe "iframe" do
    test "public recording", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :public)

      conn = get(conn, ~p"/a/#{asciicast}/iframe")

      assert html_response(conn, 200) =~ "createPlayer"
    end

    test "public recording via secret token", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :public)

      conn = get(conn, ~p"/a/#{asciicast.secret_token}/iframe")

      assert html_response(conn, 200) =~ "createPlayer"
    end

    test "private recording", %{conn: conn} do
      asciicast = insert(:asciicast, visibility: :private)

      conn = get(conn, ~p"/a/#{asciicast}/iframe")

      assert html_response(conn, 403)
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
