defmodule AsciinemaWeb.PageController do
  use AsciinemaWeb, :controller

  plug :wrap_in_container

  def about(conn, _params) do
    render(
      conn,
      "about.html",
      page_title: "About",
      contact_email_address: Application.get_env(:asciinema, :contact_email_address)
    )
  end

  def privacy(conn, _params) do
    conn
    |> assign(:page_title, "Privacy Policy")
    |> render("privacy.html")
  end

  def tos(conn, _params) do
    conn
    |> assign(:page_title, "Terms of Service")
    |> render("tos.html")
  end

  defp wrap_in_container(conn, _), do: assign(conn, :main_class, "container")
end
