defmodule AsciinemaAdmin.PlaceholderController do
  use AsciinemaAdmin, :controller

  def show(conn, _params) do
    text(conn, "asciinema admin — rebuilding")
  end
end
