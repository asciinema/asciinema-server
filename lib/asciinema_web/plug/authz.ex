defmodule AsciinemaWeb.Plug.Authz do
  alias Asciinema.Authorization
  alias AsciinemaWeb.FallbackController
  alias Plug.Conn

  def authorize(conn, assign_key) do
    resource = conn.assigns[assign_key]

    if authorized?(conn, resource) do
      conn
    else
      conn
      |> FallbackController.call({:error, :forbidden})
      |> Conn.halt()
    end
  end

  def authorized?(conn, resource) do
    user = conn.assigns[:current_user]
    action = Phoenix.Controller.action_name(conn)

    Authorization.can?(user, action, resource)
  end
end
