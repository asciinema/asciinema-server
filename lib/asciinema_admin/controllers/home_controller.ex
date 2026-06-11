defmodule AsciinemaAdmin.HomeController do
  use AsciinemaAdmin, :controller

  def show(conn, _params) do
    render(conn, :show, page_title: "Dashboard")
  end
end
