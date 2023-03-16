defmodule Asciinema.AsciicastControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  describe "auto" do
    test "lists featured asciicasts", %{conn: conn} do
      insert(:asciicast, featured: true, title: "Featured stuff")

      conn = get(conn, Routes.explore_path(conn, :auto))

      assert html_response(conn, 200) =~ "Featured stuff"
      refute html_response(conn, 200) =~ "Good stuff"
    end
  end

  describe "public" do
    test "lists public asciicasts", %{conn: conn} do
      insert(:asciicast, private: false, title: "Good stuff")

      conn = get(conn, Routes.explore_path(conn, :public))

      assert html_response(conn, 200) =~ "Good stuff"
      refute html_response(conn, 200) =~ "Featured stuff"
    end
  end

  describe "featured" do
    test "lists featured asciicasts", %{conn: conn} do
      insert(:asciicast, featured: true, title: "Featured stuff")

      conn = get(conn, Routes.explore_path(conn, :featured))

      assert html_response(conn, 200) =~ "Featured stuff"
      refute html_response(conn, 200) =~ "Good stuff"
    end
  end

  describe "show" do
    test "HTML", %{conn: conn} do
      asciicast = insert(:asciicast, title: "Good stuff")
      url = Routes.asciicast_path(conn, :show, asciicast)

      conn_2 = get(conn, url)
      assert html_response(conn_2, 200) =~ "Good stuff"
      assert response_content_type(conn_2, :html)

      conn_2 = conn |> put_req_header("accept", "*/*") |> get(url)
      assert html_response(conn_2, 200) =~ "Good stuff"
      assert response_content_type(conn_2, :html)
    end

    test "HTML, public recording via secret token", %{conn: conn} do
      asciicast = insert(:asciicast, private: false)
      conn_2 = get(conn, "/a/#{asciicast.secret_token}")
      assert redirected_to(conn_2, 302) == "/a/#{asciicast.id}"
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

    @tag :rsvg
    test "PNG", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = Routes.asciicast_path(conn, :show, asciicast)

      conn_2 = get(conn, url <> ".png")
      assert response(conn_2, 200)
      assert response_content_type(conn_2, :png)

      conn_2 = conn |> put_req_header("accept", "image/png") |> get(url)
      assert response(conn_2, 200)
      assert response_content_type(conn_2, :png)
    end

    test "SVG", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = Routes.asciicast_path(conn, :show, asciicast)

      conn_2 = get(conn, url <> ".svg")
      assert response(conn_2, 200)
      assert response_content_type(conn_2, :svg)

      conn_2 = conn |> put_req_header("accept", "image/svg+xml") |> get(url)
      assert response(conn_2, 200)
      assert response_content_type(conn_2, :svg)

      conn_2 = conn |> put_req_header("accept", "image/*") |> get(url)
      assert response(conn_2, 200)
      assert response_content_type(conn_2, :svg)
    end

    test "HTML with GIF generation instructions", %{conn: conn} do
      asciicast = insert(:asciicast)
      conn = get(conn, Routes.asciicast_path(conn, :show, asciicast) <> ".gif")
      assert html_response(conn, 200) =~ "GIF"
      assert response_content_type(conn, :html)
    end

    test "embed JS", %{conn: conn} do
      asciicast = insert(:asciicast)
      url = Routes.asciicast_path(conn, :show, asciicast)

      conn_2 = get(conn, url <> ".js")
      assert response(conn_2, 200)
      assert response_content_type(conn_2, :js)

      conn_2 = conn |> put_req_header("accept", "application/javascript") |> get(url)
      assert response(conn_2, 200)
      assert response_content_type(conn_2, :js)
    end

    test "embed iframe", %{conn: conn} do
      asciicast = fixture(:asciicast)
      conn = get(conn, Routes.asciicast_path(conn, :iframe, asciicast))
      assert html_response(conn, 200) =~ ~r/iframe\.css/
      assert html_response(conn, 200) =~ ~r/iframe\.js/
      assert html_response(conn, 200) =~ ~r/window\.players\.set/
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
      conn = get(conn, Routes.asciicast_path(conn, :edit, asciicast))
      assert redirected_to(conn, 302) == "/login/new"
    end

    test "requires author", %{conn: conn, asciicast: asciicast} do
      conn = log_in(conn, insert(:user))

      assert_raise(Asciinema.Authorization.ForbiddenError, fn ->
        get(conn, Routes.asciicast_path(conn, :edit, asciicast))
      end)
    end

    test "displays form", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)

      conn = get(conn, Routes.asciicast_path(conn, :edit, asciicast))

      assert html_response(conn, 200) =~ "Save"
    end

    test "updates title", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)

      attrs = %{asciicast: %{title: "Haha!"}}
      conn = put conn, Routes.asciicast_path(conn, :update, asciicast), attrs

      location = List.first(get_resp_header(conn, "location"))
      assert get_flash(conn, :info) =~ ~r/updated/i
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

      assert_raise(Asciinema.Authorization.ForbiddenError, fn ->
        delete(conn, Routes.asciicast_path(conn, :delete, asciicast))
      end)
    end

    test "removes and redirects", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)

      conn = delete(conn, Routes.asciicast_path(conn, :delete, asciicast))

      assert get_flash(conn, :info) =~ ~r/deleted/i
      assert response(conn, 302)

      conn = get(build_conn(), Routes.asciicast_path(conn, :show, asciicast))
      assert html_response(conn, 404) =~ ~r/not found/i
    end
  end
end
