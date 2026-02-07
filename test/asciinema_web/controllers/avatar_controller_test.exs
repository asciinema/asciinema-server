defmodule AsciinemaWeb.AvatarControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory

  describe "show" do
    test "serves image for named user", %{conn: conn} do
      user = insert(:user, username: "foobar")

      conn = get(conn, ~p"/~#{user}/avatar")

      assert response(conn, 200)
      assert List.first(get_resp_header(conn, "content-type")) =~ ~r|image/.+|
    end

    test "serves image for unnamed user", %{conn: conn} do
      user = insert(:user, username: nil)

      conn = get(conn, ~p"/~#{user}/avatar")

      assert response(conn, 200)
      assert List.first(get_resp_header(conn, "content-type")) =~ ~r|image/.+|
    end

    test "returns 404 for named user when requested via ID", %{conn: conn} do
      user = insert(:user, username: "foobar")

      conn = get(conn, ~p"/~user:#{user.id}/avatar")

      assert response(conn, 404)
    end

    test "returns 404 for unknown user", %{conn: conn} do
      conn = get(conn, ~p"/~foobar/avatar")

      assert response(conn, 404)
    end
  end
end
