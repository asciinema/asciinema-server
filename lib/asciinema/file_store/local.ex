defmodule Asciinema.FileStore.Local do
  @behaviour Asciinema.FileStore
  import Plug.Conn
  alias Plug.MIME

  def serve_file(conn, path, nil) do
    do_serve_file(conn, path)
  end
  def serve_file(conn, path, filename) do
    conn
    |> put_resp_header("content-disposition", "attachment; filename=#{filename}")
    |> do_serve_file(path)
  end

  defp do_serve_file(conn, path) do
    conn
    |> put_resp_header("content-type", MIME.path(path))
    |> send_file(200, base_path() <> path)
    |> halt
  end

  defp config do
    Application.get_env(:asciinema, Asciinema.FileStore.Local)
  end

  defp base_path do
    Keyword.get(config(), :path)
  end
end
