defmodule AsciinemaWeb.UserStreamControllerTest do
  use AsciinemaWeb.ConnCase, async: false
  import Asciinema.Factory
  import AsciinemaWeb.PaginationTestHelpers

  setup :setup_pagination_limits

  describe "live/2 pagination" do
    test "applies guest/authenticated limits and owner bypass", %{conn: conn} do
      owner = insert(:user)
      viewer = insert(:user)
      insert_list(141, :stream, user: owner, visibility: :public, live: true)

      guest_response =
        conn
        |> get("/~#{owner.username}/streams/live?page=11")
        |> html_response(200)

      assert_active_page(guest_response, 9)
      refute guest_response =~ ~s(href="?page=10")
      refute guest_response =~ ~s(href="?page=11")

      authenticated_response =
        build_conn()
        |> log_in(viewer)
        |> get("/~#{owner.username}/streams/live?page=11")
        |> html_response(200)

      assert_active_page(authenticated_response, 10)
      assert authenticated_response =~ ~s(href="?page=9")
      refute authenticated_response =~ ~s(href="?page=11")

      owner_response =
        build_conn()
        |> log_in(owner)
        |> get("/~#{owner.username}/streams/live?page=11")
        |> html_response(200)

      assert_active_page(owner_response, 11)
    end
  end
end
