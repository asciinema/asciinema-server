defmodule Asciinema.FileStore.S3 do
  @behaviour Asciinema.FileStore
  import Phoenix.Controller, only: [redirect: 2]
  alias ExAws.S3

  def put_file(dst_path, src_local_path, content_type) do
    body = File.read!(src_local_path)
    opts = [{:content_type, content_type}]
    make_request(S3.put_object(bucket(), base_path() <> dst_path, body, opts))
  end

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

  def open(path, function \\ nil) do
    response = S3.get_object(bucket(), base_path() <> path) |> ExAws.request(region: region())
    # TODO: use make_request

    case response do
      {:ok, %{body: body}} ->
        if function do
          File.open(body, [:ram, :binary, :read], function)
        else
          File.open(body, [:ram, :binary, :read])
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp make_request(request) do
    with {:ok, _} <- ExAws.request(request, region: region()) do
      :ok
    end
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
