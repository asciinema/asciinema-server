defmodule AsciinemaWeb.Plug.ReturnTo do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  def save_return_path(conn) do
    qs = if conn.query_string != "", do: "?#{conn.query_string}", else: ""
    put_session(conn, :return_to, conn.request_path <> qs)
  end

  def redirect_back_or(conn, target) do
    target =
      if return_to = get_session(conn, :return_to) do
        [to: return_to]
      else
        target
      end

    conn
    |> clear_return_path()
    |> redirect(target)
    |> halt()
  end

  def clear_return_path(conn) do
    delete_session(conn, :return_to)
  end
end
