defmodule AsciinemaWeb.Authorization do
  alias Asciinema.Authorization

  def can?(user, :edit, resource), do: Authorization.can?(user, :update, resource)
  def can?(user, :iframe, resource), do: Authorization.can?(user, :show, resource)
  def can?(user, action, resource), do: Authorization.can?(user, action, resource)

  defdelegate scope(query, relations, user), to: Authorization
end
