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

  defp wrap_in_container(conn, _), do: assign(conn, :main_class, "container")
end
