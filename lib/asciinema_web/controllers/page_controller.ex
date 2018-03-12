defmodule AsciinemaWeb.PageController do
  use AsciinemaWeb, :controller

  plug :put_layout, :app2

  def privacy(conn, _params) do
    conn
    |> assign(:page_title, "Privacy Policy")
    |> render("privacy.html")
  end
end
