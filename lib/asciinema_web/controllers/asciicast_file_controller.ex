defmodule AsciinemaWeb.AsciicastFileController do
  use AsciinemaWeb, :controller
  alias Asciinema.Asciicasts
  alias Asciinema.Asciicasts.Asciicast

  def show(conn, %{"id" => id} = params) do
    asciicast = Asciicasts.get_asciicast!(id)
    path = Asciicast.json_store_path(asciicast)
    filename = download_filename(asciicast, params)

    file_store().serve_file(conn, path, filename)
  end

  defp download_filename(%Asciicast{version: version, id: id}, %{"dl" => _}) do
    case version do
      0 -> "#{id}.json"
      1 -> "#{id}.json"
      2 -> "#{id}.cast"
    end
  end
  defp download_filename(_asciicast, _params) do
    nil
  end

  defp file_store do
    Application.get_env(:asciinema, :file_store)
  end
end
