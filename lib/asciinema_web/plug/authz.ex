defmodule AsciinemaWeb.Plug.Authz do
  alias Asciinema.Authorization
  alias AsciinemaWeb.FallbackController
  alias Plug.Conn

  def authorize(conn, assign_key) do
    user = conn.assigns[:current_user]
    action = Phoenix.Controller.action_name(conn)
    resource = conn.assigns[assign_key]

    if Authorization.can?(user, action, resource) do
      conn
    else
      conn
      |> FallbackController.call({:error, :forbidden})
      |> Conn.halt()
    end
  end
end
