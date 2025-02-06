defmodule AsciinemaWeb.Admin.HomeController do
  use AsciinemaWeb, :controller

  def show(conn, _params) do
    conn
    |> put_layout(:admin)
    |> render(:show)
  end
end
