defmodule AsciinemaWeb.PaginationHelpers do
  @guest_config_key :guest_pagination_max_pages
  @authenticated_config_key :authenticated_pagination_max_pages

  def pagination_opts(conn, opts \\ [])

  def pagination_opts(%{assigns: %{current_user: nil}}, _opts) do
    config_opts(@guest_config_key)
  end

  def pagination_opts(%{assigns: %{current_user: %{id: current_user_id}}}, opts) do
    if opts[:owner_id] == current_user_id do
      []
    else
      config_opts(@authenticated_config_key)
    end
  end

  defp config_opts(key) do
    if max_pages = Application.get_env(:asciinema, key) do
      [max_pages: max_pages]
    else
      []
    end
  end
end
