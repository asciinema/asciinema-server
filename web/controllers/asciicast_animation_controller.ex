defmodule Asciinema.AsciicastAnimationController do
  use Asciinema.Web, :controller
  alias Asciinema.{Repo, Asciicast}

  def show(conn, %{"id" => id}) do
    asciicast = Repo.one!(Asciicast.by_id_or_secret_token(id))

    conn
    |> put_layout("simple.html")
    |> render("show.html", file_url: asciicast_file_download_url(conn, asciicast))
  end
end
