defmodule AsciinemaWeb.SearchControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory
  alias Asciinema.Recordings

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
  end
end
