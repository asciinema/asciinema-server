defmodule AsciinemaWeb.WebsocketUpgrade do
  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(handler_module), do: handler_module

  @impl true
  def call(conn, handler_module) do
    handler_module.upgrade(conn, conn.path_params)
  rescue
    WebSockAdapter.UpgradeError ->
      conn
      |> send_resp(400, "")
      |> halt()
  end
end
