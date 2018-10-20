defmodule AsciinemaWeb.Plug.Authz do
  def authorize(conn, assign_key) do
    user = conn.assigns.current_user
    action = Phoenix.Controller.action_name(conn)
    resource = conn.assigns[assign_key]
    Asciinema.Authorization.can!(user, action, resource)
    conn
  end
end
