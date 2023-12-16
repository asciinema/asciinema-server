defmodule AsciinemaWeb.PageController do
  use AsciinemaWeb, :controller

  def about(conn, _params) do
    render(
      conn,
      "about.html",
      page_title: "About",
      contact_email_address: Application.get_env(:asciinema, :contact_email_address)
    )
  end
end
