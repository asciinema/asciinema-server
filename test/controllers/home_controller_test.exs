defmodule Asciinema.HomeControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  describe "home page" do
    test "renders", %{conn: conn} do
      conn = get(conn, "/")

      assert html_response(conn, 200)
    end

    test "asciicast visibility", %{conn: conn} do
      user = insert(:user, username: "dracula3000")
      insert(:asciicast, user: user, featured: true, title: "Featured stuff")
      insert(:asciicast, user: user, featured: false, title: "Normal stuff")

      conn = get(conn, "/")

      html = html_response(conn, 200)
      assert html =~ "dracula3000"
      assert html =~ "Featured stuff"
      refute html =~ "Normal stuff"
    end
  end
end
