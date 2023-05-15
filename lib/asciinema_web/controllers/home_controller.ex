defmodule AsciinemaWeb.HomeController do
  use AsciinemaWeb, :controller
  alias Asciinema.Recordings

  plug :clear_main_class

  def show(conn, _params) do
    asciicast = Recordings.get_homepage_asciicast()
    asciicasts = Recordings.list_homepage_asciicasts()

    render(
      conn,
      "show.html",
      asciicast: asciicast,
      asciicasts: asciicasts
    )
  end
end
