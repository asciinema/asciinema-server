defmodule Asciinema.FileStore.S3 do
  use Asciinema.FileStore
  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn
  alias ExAws.{S3, Config}

  @impl true
  def url(path) do
    url(path, [])
  end

  def url(path, query_params) do
    {:ok, url} =
      Config.new(:s3)
      |> S3.presigned_url(:get, bucket(), base_path() <> path, query_params: query_params)

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
  def serve_file(conn, path, filename) do
    do_serve_file(conn, path, filename, proxy?())
  end

  defp do_serve_file(conn, path, filename, false) do
    redirect(conn, external: url(path, s3_response_params(filename)))
  end

  defp do_serve_file(conn, path, filename, true) do
    conn
    |> put_resp_header("x-accel-redirect", "/_proxy/#{path}")
    |> put_resp_header("redirect-uri", url(path))
    |> put_content_disposition(filename)
    |> send_resp(200, "")
  end

  defp s3_response_params(nil), do: []

  defp s3_response_params(filename) do
    ["response-content-disposition": "attachment; filename=#{filename}"]
  end

  defp put_content_disposition(conn, nil), do: conn

  defp put_content_disposition(conn, filename) do
    put_resp_header(conn, "content-disposition", "attachment; filename=#{filename}")
  end

  @impl true
  def open_file(path, function \\ nil) do
    response = bucket() |> S3.get_object(base_path() <> path) |> make_request()

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

  defp config do
    Application.get_env(:asciinema, __MODULE__)
  end

  defp bucket do
    Keyword.get(config(), :bucket)
  end

  defp proxy? do
    Keyword.get(config(), :proxy, false)
  end

  defp base_path do
    Keyword.get(config(), :path)
  end
end
