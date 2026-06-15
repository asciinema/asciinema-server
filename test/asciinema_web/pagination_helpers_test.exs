defmodule AsciinemaWeb.PaginationHelpersTest do
  use ExUnit.Case, async: true

  alias Asciinema.AppEnv
  alias AsciinemaWeb.PaginationHelpers

  describe "pagination_opts/1" do
    test "returns no limit for guests when config is missing" do
      assert PaginationHelpers.pagination_opts(%{assigns: %{current_user: nil}}) == []
    end

    test "returns limit for guests when config is set" do
      AppEnv.put(:guest_pagination_max_pages, 7)

      assert PaginationHelpers.pagination_opts(%{assigns: %{current_user: nil}}) == [max_pages: 7]
    end

    test "returns no limit for logged-in users when config is missing" do
      assert PaginationHelpers.pagination_opts(%{assigns: %{current_user: %{id: 1}}}) == []
    end

    test "returns limit for logged-in users when config is set" do
      AppEnv.put(:authenticated_pagination_max_pages, 11)

      assert PaginationHelpers.pagination_opts(%{assigns: %{current_user: %{id: 1}}}) == [
               max_pages: 11
             ]
    end

    test "returns no limit for owners even when authenticated config is set" do
      AppEnv.put(:authenticated_pagination_max_pages, 11)

      assert PaginationHelpers.pagination_opts(
               %{assigns: %{current_user: %{id: 1}}},
               owner_id: 1
             ) == []
    end

    test "returns authenticated limit for non-owners when authenticated config is set" do
      AppEnv.put(:authenticated_pagination_max_pages, 11)

      assert PaginationHelpers.pagination_opts(
               %{assigns: %{current_user: %{id: 1}}},
               owner_id: 2
             ) == [max_pages: 11]
    end
  end
end
