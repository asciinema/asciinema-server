defmodule AsciinemaWeb.HomeController do
  use AsciinemaWeb, :controller
  alias Asciinema.Asciicasts

  plug :clear_main_class
  plug :use_player_v3, force: true

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
