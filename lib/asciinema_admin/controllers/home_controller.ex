defmodule AsciinemaAdmin.HomeController do
  use AsciinemaAdmin, :controller

  def show(conn, _params) do
    redirect(conn, to: ~p"/admin/users")
  end
end
