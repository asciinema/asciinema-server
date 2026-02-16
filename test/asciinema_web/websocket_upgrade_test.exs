defmodule AsciinemaWeb.WebsocketUpgradeTest do
  use AsciinemaWeb.ConnCase, async: true

  describe "upgrade validation" do
    test "returns 400 for non-upgrade request on producer socket path", %{conn: conn} do
      conn = get(conn, "/ws/S/token")

      assert conn.status == 400
    end

    test "returns 400 for non-upgrade request on consumer socket path", %{conn: conn} do
      conn = get(conn, "/ws/s/token")

      assert conn.status == 400
    end
  end
end
