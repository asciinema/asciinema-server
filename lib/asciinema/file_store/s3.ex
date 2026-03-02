defmodule Asciinema.FileStore.S3 do
  use Asciinema.Config
  alias ExAws.{S3, Config}

  @behaviour Asciinema.FileStore

  @impl true
  def uri(path) do
    {:ok, url} =
      :s3
      |> Config.new()
      |> S3.presigned_url(:get, bucket(), base_path() <> path)

    url
  end

  @impl true
  def put_file(dst_path, src_local_path, content_type) do
    body = File.read!(src_local_path)
    opts = [{:content_type, content_type}]

    with {:ok, _} <- make_request(S3.put_object(bucket(), base_path() <> dst_path, body, opts)) do
      :ok
    end
  end

  @impl true
  def move_file(from_path, to_path) do
    req =
      S3.put_object_copy(
        bucket(),
        base_path() <> to_path,
        bucket(),
        base_path() <> from_path
      )

    case make_request(req) do
      {:ok, _} ->
        delete_file(from_path)

      {:error, {:http_error, 404, _}} ->
        {:error, :enoent}
    end
  end

  @impl true
  def get_local_path(path) do
    response =
      bucket()
      |> S3.get_object(base_path() <> path)
      |> make_request()

    with {:ok, %{headers: headers, body: body}} <- response do
      body =
        case List.keyfind(headers, "Content-Encoding", 0) do
          {"Content-Encoding", "gzip"} -> :zlib.gunzip(body)
          _ -> body
        end

      {:ok, tmp_path} = Briefly.create()
      File.write!(tmp_path, body)

      {:ok, tmp_path}
    end
  end

  @impl true
  def delete_file(path) do
    req = S3.delete_object(bucket(), base_path() <> path)

    with {:ok, _} <- make_request(req) do
      :ok
    end
  end

  defp make_request(request) do
    ExAws.request(request)
  end

  defp bucket, do: config(:bucket)

  defp base_path, do: config(:path)
end
