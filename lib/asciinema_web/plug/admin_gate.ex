defmodule AsciinemaWeb.Plug.AdminGate do
  @moduledoc """
  Serves the admin panel on the main endpoint: dispatches /admin requests to
  AsciinemaAdmin.Router for admins, sends anonymous users to the login page,
  and 404s non-admins so the panel's existence isn't advertised.
  """

  import Plug.Conn
  alias Asciinema.Accounts.User
  alias AsciinemaWeb.Authentication

  def init(opts), do: opts

  def call(%Plug.Conn{path_info: ["admin" | _]} = conn, _opts) do
    conn =
      conn
      |> fetch_session()
      |> AsciinemaWeb.Plug.Authn.call([])

    case conn.assigns.current_user do
      %User{is_admin: true} ->
        conn
        |> AsciinemaAdmin.Router.call(AsciinemaAdmin.Router.init([]))
        |> halt()

      %User{} ->
        raise Phoenix.Router.NoRouteError, conn: conn, router: AsciinemaWeb.Router

      nil ->
        conn
        |> Phoenix.Controller.fetch_flash()
        |> Authentication.require_current_user([])
    end
  end

  def call(conn, _opts), do: conn
end
