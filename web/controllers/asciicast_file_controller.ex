defmodule Asciinema.AsciicastFileController do
  use Asciinema.Web, :controller
  alias Asciinema.{Asciicasts, Asciicast}

  def show(conn, %{"id" => id} = params) do
    asciicast = Asciicasts.get_asciicast!(id)
    path = Asciicast.json_store_path(asciicast)
    filename = download_filename(asciicast, params)

    file_store().serve_file(conn, path, filename)
  end

  defp download_filename(%Asciicast{id: id}, %{"dl" => _}) do
    "asciicast-#{id}.json"
  end
  defp download_filename(_asciicast, _params) do
    nil
  end

  defp file_store do
    Application.get_env(:asciinema, :file_store)
  end
end
