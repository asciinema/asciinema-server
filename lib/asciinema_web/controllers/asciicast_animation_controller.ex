defmodule AsciinemaWeb.AsciicastAnimationController do
  use AsciinemaWeb, :controller
  alias Asciinema.Asciicasts

  def show(conn, %{"id" => id}) do
    asciicast = Asciicasts.get_asciicast!(id)

    conn
    |> put_layout("simple.html")
    |> render("show.html", file_url: asciicast_file_download_url(conn, asciicast))
  end
end
