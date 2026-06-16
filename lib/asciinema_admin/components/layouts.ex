defmodule AsciinemaAdmin.Layouts do
  use AsciinemaAdmin, :html

  embed_templates "layouts/*"

  @env Atom.to_string(Mix.env())
  def env_name, do: @env

  @doc "Running server version, or nil when unset (same source as /about)."
  def version, do: Application.get_env(:asciinema, :version)

  @doc """
  Returns "active" if `path` matches `target` exactly, or is nested under it
  (except for `/admin` itself, which only matches exactly so it doesn't light
  up on every page).
  """
  def nav_class(nil, _target), do: nil
  def nav_class(path, "/admin") when path in ["/admin", "/admin/"], do: "active"
  def nav_class(_, "/admin"), do: nil

  def nav_class(path, target) do
    if path == target or String.starts_with?(path, target <> "/"), do: "active"
  end
end
