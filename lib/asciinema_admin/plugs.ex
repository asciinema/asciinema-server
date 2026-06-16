defmodule AsciinemaAdmin.Plugs do
  @moduledoc "Plugs shared by admin controllers."

  import Plug.Conn

  def put_current_path(conn, _opts) do
    assign(conn, :current_path, conn.request_path)
  end
end
