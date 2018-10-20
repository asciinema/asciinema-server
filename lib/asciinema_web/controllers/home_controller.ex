defmodule AsciinemaWeb.HomeController do
  use AsciinemaWeb, :controller
  alias Asciinema.Asciicasts

  plug :put_layout, :app2
  plug :clear_main_class

  def show(conn, _params) do
    asciicast = Asciicasts.get_homepage_asciicast()
    asciicasts = Asciicasts.list_homepage_asciicasts()

    render(
      conn,
      "show.html",
      asciicast: asciicast,
      asciicasts: asciicasts
    )
  end
end
