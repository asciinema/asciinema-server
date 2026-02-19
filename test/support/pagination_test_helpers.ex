defmodule AsciinemaWeb.PaginationTestHelpers do
  import ExUnit.Assertions
  import ExUnit.Callbacks

  @guest_key :guest_pagination_max_pages
  @authenticated_key :authenticated_pagination_max_pages
  @guest_limit 9
  @authenticated_limit 10

  def setup_pagination_limits(_context) do
    {previous_guest_limit, previous_authenticated_limit} = remember_limits()

    Application.put_env(:asciinema, @guest_key, @guest_limit)
    Application.put_env(:asciinema, @authenticated_key, @authenticated_limit)

    on_exit(fn ->
      restore_limits(previous_guest_limit, previous_authenticated_limit)
    end)

    :ok
  end

  def setup_pagination_env_cleanup(_context) do
    {previous_guest_limit, previous_authenticated_limit} = remember_limits()

    on_exit(fn ->
      restore_limits(previous_guest_limit, previous_authenticated_limit)
    end)

    :ok
  end

  def assert_active_page(response, page) do
    assert response =~ ~r/class="active">\s*#{page}\s*<\/a>/
  end

  defp remember_limits do
    previous_guest_limit = Application.get_env(:asciinema, @guest_key)
    previous_authenticated_limit = Application.get_env(:asciinema, @authenticated_key)
    {previous_guest_limit, previous_authenticated_limit}
  end

  defp restore_limits(previous_guest_limit, previous_authenticated_limit) do
    restore_limit(@guest_key, previous_guest_limit)
    restore_limit(@authenticated_key, previous_authenticated_limit)
  end

  defp restore_limit(key, nil), do: Application.delete_env(:asciinema, key)
  defp restore_limit(key, value), do: Application.put_env(:asciinema, key, value)
end
