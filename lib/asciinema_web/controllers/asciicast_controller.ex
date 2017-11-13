defmodule AsciinemaWeb.AsciicastController do
  use AsciinemaWeb, :controller
  alias Asciinema.Asciicasts

  def iframe(conn, %{"id" => id}) do
    asciicast = Asciicasts.get_asciicast!(id)

    conn
    |> put_layout("iframe.html")
    |> delete_resp_header("x-frame-options")
    |> render("iframe.html", file_url: asciicast_file_download_url(conn, asciicast))
  end
end
