defmodule Asciinema.AsciicastControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  test "index", %{conn: conn} do
    conn = get conn, asciicast_path(conn, :index)

    assert redirected_to(conn, 302) =~ "/explore/featured"
  end

  test "public", %{conn: conn} do
    insert(:asciicast, private: false, title: "Good stuff")

    conn = get conn, asciicast_path(conn, :category, :public)

    assert html_response(conn, 200) =~ "Good stuff"
    refute html_response(conn, 200) =~ "Featured stuff"
  end

  test "featured", %{conn: conn} do
    insert(:asciicast, featured: true, title: "Featured stuff")

    conn = get conn, asciicast_path(conn, :category, :featured)

    assert html_response(conn, 200) =~ "Featured stuff"
    refute html_response(conn, 200) =~ "Good stuff"
  end

  test "shows asciicast file, v1 format", %{conn: conn} do
    asciicast = fixture(:asciicast_v1)
    width = asciicast.terminal_columns
    conn = get conn, asciicast_file_path(conn, asciicast)
    assert %{"version" => 1,
             "width" => ^width,
             "stdout" => [_ | _]} = json_response(conn, 200)
  end

  test "shows asciicast file, v2 format", %{conn: conn} do
    asciicast = fixture(:asciicast_v2)
    conn = get conn, asciicast_file_path(conn, asciicast)
    assert response(conn, 200)
  end

  @tag :a2png
  test "shows png preview", %{conn: conn} do
    asciicast = fixture(:asciicast)
    conn = get conn, asciicast_image_path(conn, asciicast)
    assert response(conn, 200)
    assert response_content_type(conn, :png)
  end

  test "shows SVG doc", %{conn: conn} do
    asciicast = insert(:asciicast)
    conn = get conn, asciicast_path(conn, :show, asciicast) <> ".svg"
    assert response(conn, 200)
    assert response_content_type(conn, :svg)
  end

  test "shows GIF generation instructions", %{conn: conn} do
    asciicast = fixture(:asciicast)
    conn = get conn, asciicast_animation_path(conn, asciicast)
    assert html_response(conn, 200) =~ "GIF"
    assert response_content_type(conn, :html)
  end

  test "shows embed js", %{conn: conn} do
    asciicast = fixture(:asciicast)
    conn = get conn, asciicast_path(conn, :show, asciicast) <> ".js"
    assert response(conn, 200)
    assert response_content_type(conn, :js)
  end

  test "shows embed html (used in iframe)", %{conn: conn} do
    asciicast = fixture(:asciicast)
    conn = get conn, asciicast_path(conn, :embed, asciicast)
    assert html_response(conn, 200) =~ ~r/<asciinema-player /
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
      conn = get conn, asciicast_path(conn, :edit, asciicast)
      assert redirected_to(conn, 302) == "/login/new"
    end

    test "requires author", %{conn: conn, asciicast: asciicast} do
      conn = log_in(conn, insert(:user))

      assert_raise(Asciinema.Authorization.ForbiddenError, fn ->
        get conn, asciicast_path(conn, :edit, asciicast)
      end)
    end

    test "displays form", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)

      conn = get conn, asciicast_path(conn, :edit, asciicast)

      assert html_response(conn, 200) =~ "Save"
    end

    test "updates title", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)

      attrs = %{asciicast: %{title: "Haha!"}}
      conn = put conn, asciicast_path(conn, :update, asciicast), attrs

      location = List.first(get_resp_header(conn, "location"))
      assert get_flash(conn, :info) =~ ~r/updated/i
      assert response(conn, 302)

      conn = get build_conn(), location

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
        delete conn, asciicast_path(conn, :delete, asciicast)
      end)
    end

    test "removes and redirects", %{conn: conn, asciicast: asciicast, user: user} do
      conn = log_in(conn, user)

      conn = delete conn, asciicast_path(conn, :delete, asciicast)

      assert get_flash(conn, :info) =~ ~r/deleted/i
      assert response(conn, 302)

      assert_raise(Ecto.NoResultsError, fn ->
        get build_conn(), asciicast_path(conn, :show, asciicast)
      end)
    end
  end
end
