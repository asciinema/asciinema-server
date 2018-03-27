defmodule AsciinemaWeb.PageController do
  use AsciinemaWeb, :controller

  plug :put_layout, :app2

  def about(conn, _params) do
    conn
    |> assign(:page_title, "About")
    |> render("about.html")
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

  def contact(conn, _params) do
    conn
    |> assign(:page_title, "Contact")
    |> render("contact.html") # TODO rename to Community
  end

  def contributing(conn, _params) do
    conn
    |> assign(:page_title, "Contributing")
    |> render("contributing.html")
  end
end
