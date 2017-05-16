defmodule Asciinema.AsciicastFileController do
  use Asciinema.Web, :controller
  alias Asciinema.{Repo, Asciicast}

  def show(conn, %{"id" => id} = params) do
    asciicast = Repo.one!(Asciicast.by_id_or_secret_token(id))
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
