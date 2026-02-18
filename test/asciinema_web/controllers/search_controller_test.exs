defmodule AsciinemaWeb.SearchControllerTest do
  use AsciinemaWeb.ConnCase, async: false
  import Asciinema.Factory
  import AsciinemaWeb.PaginationTestHelpers
  alias Asciinema.Recordings

  setup :setup_pagination_limits

  setup do
    user = insert(:user)

    insert(:asciicast, title: "Foo 1", visibility: :public)
    insert(:asciicast, title: "Foo 2", visibility: :unlisted)
    insert(:asciicast, title: "Foo 3", visibility: :private)

    insert(:asciicast,
      title: "Another 1",
      description: "Foo bar",
      visibility: :unlisted,
      user: user
    )

    :asciicast_v3
    |> insert(title: "Another 2", visibility: :public)
    |> with_file()
    |> Recordings.update_fts_content()

    %{user: user}
  end

  describe "show" do
    test "returns matching public recordings", %{conn: conn} do
      conn = get(conn, ~p"/search?q=foo")

      response = html_response(conn, 200)

      assert response =~ "Foo 1"
      refute response =~ "Foo 2"
      refute response =~ "Foo 3"
      refute response =~ "Another 1"
      assert response =~ "Another 2"
    end

    test "includes user's own recordings", %{conn: conn, user: user} do
      conn = log_in(conn, user)
      conn = get(conn, ~p"/search?q=foo")

      response = html_response(conn, 200)

      assert response =~ "Foo 1"
      refute response =~ "Foo 2"
      refute response =~ "Foo 3"
      assert response =~ "Another 1"
      assert response =~ "Another 2"
    end

    test "displays instructions when no results", %{conn: conn} do
      conn = get(conn, ~p"/search?q=nope")

      response = html_response(conn, 200)

      refute response =~ "Foo 1"
      refute response =~ "Foo 2"
      refute response =~ "Foo 3"
      refute response =~ "Another 1"
      refute response =~ "Another 2"
      assert response =~ "No matching results"
    end

    test "applies guest and authenticated limits", %{conn: conn, user: user} do
      insert_list(241, :asciicast, title: "Foo foo", visibility: :public)

      guest_response =
        conn
        |> get(~p"/search?q=foo&page=11")
        |> html_response(200)

      assert_active_page(guest_response, 9)
      refute guest_response =~ ~s(href="?page=10&amp;q=foo")
      refute guest_response =~ ~s(href="?page=11&amp;q=foo")

      authenticated_response =
        build_conn()
        |> log_in(user)
        |> get(~p"/search?q=foo&page=11")
        |> html_response(200)

      assert_active_page(authenticated_response, 10)
      assert authenticated_response =~ ~s(href="?page=9&amp;q=foo")
      refute authenticated_response =~ ~s(href="?page=11&amp;q=foo")
    end
  end
end
