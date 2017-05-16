defmodule Asciinema.FileStore.S3 do
  @behaviour Asciinema.FileStore
  import Phoenix.Controller, only: [redirect: 2]

  def serve_file(conn, path, nil) do
    do_serve_file(conn, path)
  end
  def serve_file(conn, path, filename) do
    do_serve_file(conn, path, ["response-content-disposition": "attachment; filename=#{filename}"])
  end

  defp do_serve_file(conn, path, query_params \\ []) do
    {:ok, url} =
      ExAws.Config.new(:s3, region: region())
      |> ExAws.S3.presigned_url(:get, bucket(), base_path() <> path, query_params: query_params)

    conn
    |> redirect(external: url)
  end

  defp config do
    Application.get_env(:asciinema, Asciinema.FileStore.S3)
  end

  defp region do
    Keyword.get(config(), :region)
  end

  defp bucket do
    Keyword.get(config(), :bucket)
  end

  defp base_path do
    Keyword.get(config(), :path)
  end
end
