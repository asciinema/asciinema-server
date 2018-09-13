defmodule Asciinema.FileStore.S3 do
  use Asciinema.FileStore
  import Phoenix.Controller, only: [redirect: 2]
  alias ExAws.{S3, Config}

  def url(path) do
    url(path, [])
  end

  def url(path, query_params) do
    {:ok, url} =
      Config.new(:s3, region: region())
      |> S3.presigned_url(:get, bucket(), base_path() <> path, query_params: query_params)

    url
  end

  def put_file(dst_path, src_local_path, content_type, compress \\ false) do
    {body, opts} = if compress do
      body = src_local_path |> File.read! |> :zlib.gzip
      opts = [{:content_type, content_type}, {:content_encoding, "gzip"}]
      {body, opts}
    else
      body = File.read!(src_local_path)
      opts = [{:content_type, content_type}]
      {body, opts}
    end

    with {:ok, _} <- make_request(S3.put_object(bucket(), base_path() <> dst_path, body, opts)) do
      :ok
    end
  end

  def serve_file(conn, path, nil) do
    do_serve_file(conn, path)
  end
  def serve_file(conn, path, filename) do
    do_serve_file(conn, path, ["response-content-disposition": "attachment; filename=#{filename}"])
  end

  defp do_serve_file(conn, path, query_params \\ []) do
    redirect(conn, external: url(path, query_params))
  end

  def open_file(path, function \\ nil) do
    response = bucket() |> S3.get_object(base_path() <> path) |> make_request

    with {:ok, %{headers: headers, body: body}} <- response do
      body =
        case List.keyfind(headers, "Content-Encoding", 0) do
          {"Content-Encoding", "gzip"} -> :zlib.gunzip(body)
          _ -> body
        end

      if function do
        File.open(body, [:ram, :binary, :read], function)
      else
        File.open(body, [:ram, :binary, :read])
      end
    end
  end

  defp make_request(request) do
    ExAws.request(request, region: region())
  end

  defp config do
    Application.get_env(:asciinema, __MODULE__)
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
