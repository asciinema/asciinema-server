defmodule AsciinemaAdmin.RedirectController do
  use AsciinemaAdmin, :controller

  def to_admin(conn, _params), do: redirect(conn, to: ~p"/admin")
end
