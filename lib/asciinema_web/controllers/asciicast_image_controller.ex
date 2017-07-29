defmodule AsciinemaWeb.AsciicastImageController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Asciicasts, PngGenerator}
  alias Asciinema.Asciicasts.Asciicast

  @max_age 604800 # 7 days

  def show(conn, %{"id" => id} = _params) do
    asciicast = Asciicasts.get_asciicast!(id)
    user = Repo.preload(asciicast, :user).user
    png_params = Asciicast.png_params(asciicast, user)

    case PngGenerator.generate(asciicast, png_params) do
      {:ok, png_path} ->
        conn
        |> put_resp_header("content-type", MIME.from_path(png_path))
        |> put_resp_header("cache-control", "public, max-age=#{@max_age}")
        |> send_file(200, png_path)
        |> halt
      {:error, :busy} ->
        conn
        |> put_resp_header("retry-after", "5")
        |> send_resp(503, "")
    end
  end
end
