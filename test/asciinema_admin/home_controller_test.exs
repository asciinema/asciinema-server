defmodule AsciinemaAdmin.HomeControllerTest do
  use AsciinemaAdmin.ConnCase, async: true

  describe "GET /admin" do
    test "renders the dashboard with stats, sparklines, and recent activity", %{conn: conn} do
      insert_list(2, :user)
      insert_list(2, :asciicast)
      insert(:stream, live: true)

      body = conn |> get(~p"/admin") |> html_response(200)

      assert body =~ "Dashboard"
      assert body =~ "Users"
      assert body =~ "Recordings"
      assert body =~ "Streams"
      assert body =~ "live / total"
      # three-window growth strip
      assert body =~ "today"
      assert body =~ "7d"
      assert body =~ "30d"
      assert body =~ "Daily signups"
      assert body =~ "Daily recordings"
      assert body =~ "last 30 days"
      assert body =~ "Recent signups"
      assert body =~ "Recent recordings"
      assert body =~ "Stream activity"
    end

    test "renders cleanly with an empty database (no recordings, no streams)", %{conn: conn} do
      body = conn |> get(~p"/admin") |> html_response(200)

      assert body =~ "Dashboard"
      assert body =~ "No streams yet."
    end
  end
end
