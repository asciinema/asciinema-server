defmodule Asciinema.AsciicastImageController do
  use Asciinema.Web, :controller
  alias Asciinema.{Repo, Asciicast, PngGenerator}
  alias Plug.MIME

  def show(conn, %{"id" => id} = _params) do
    asciicast = Repo.one!(Asciicast.by_id_or_secret_token(id))
    {:ok, png_path} = PngGenerator.generate(asciicast)

    conn
    |> put_resp_header("content-type", MIME.path(png_path))
    |> send_file(200, png_path)
    |> halt
  end
end
