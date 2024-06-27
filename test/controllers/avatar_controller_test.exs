defmodule Asciinema.AvatarControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  test "image response", %{conn: conn} do
    user = insert(:user)

    conn = get(conn, ~p"/u/#{user}/avatar")

    assert response(conn, 200)
    assert List.first(get_resp_header(conn, "content-type")) =~ ~r|image/.+|
  end
end
