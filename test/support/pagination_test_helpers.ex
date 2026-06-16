defmodule AsciinemaWeb.PaginationTestHelpers do
  import ExUnit.Assertions
  alias Asciinema.AppEnv

  @guest_key :guest_pagination_max_pages
  @authenticated_key :authenticated_pagination_max_pages
  @guest_limit 9
  @authenticated_limit 10

  def setup_pagination_limits(_context) do
    AppEnv.put(@guest_key, @guest_limit)
    AppEnv.put(@authenticated_key, @authenticated_limit)

    :ok
  end

  def assert_active_page(response, page) do
    assert response =~ ~r/class="active">\s*#{page}\s*<\/a>/
  end
end
