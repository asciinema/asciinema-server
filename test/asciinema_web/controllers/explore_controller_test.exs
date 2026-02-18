defmodule AsciinemaWeb.ExploreControllerTest do
  use AsciinemaWeb.ConnCase, async: false
  import Asciinema.Factory
  import AsciinemaWeb.PaginationTestHelpers

  setup :setup_pagination_limits

  describe "recent_recordings/2 pagination" do
    test "applies guest and authenticated limits", %{conn: conn} do
      user = insert(:user)
      insert_list(141, :asciicast, visibility: :public)

      guest_response =
        conn
        |> get(~p"/explore/recordings/recent?page=11")
        |> html_response(200)

      assert_active_page(guest_response, 9)
      refute guest_response =~ ~s(href="?page=10")
      refute guest_response =~ ~s(href="?page=11")

      authenticated_response =
        build_conn()
        |> log_in(user)
        |> get(~p"/explore/recordings/recent?page=11")
        |> html_response(200)

      assert_active_page(authenticated_response, 10)
      assert authenticated_response =~ ~s(href="?page=9")
      refute authenticated_response =~ ~s(href="?page=11")
    end
  end
end
