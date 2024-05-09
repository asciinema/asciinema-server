defmodule Asciinema.FileStore.Local do
  use Asciinema.FileStore
  import Plug.Conn

  @impl true
  def url(_path) do
    nil
  end

  @impl true
  def put_file(dst_path, src_local_path, _content_type) do
    full_dst_path = full_path(dst_path)
    parent_dir = Path.dirname(full_dst_path)

    with :ok <- File.mkdir_p(parent_dir),
         {:ok, _} <- File.copy(src_local_path, full_dst_path) do
      :ok
    end
  end

  @impl true
  def move_file(from_path, to_path) do
    full_from_path = full_path(from_path)
    full_to_path = full_path(to_path)
    parent_dir = Path.dirname(full_to_path)
    :ok = File.mkdir_p(parent_dir)
    File.rename(full_from_path, full_to_path)
  end

  @impl true
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
    |> put_resp_header("content-type", MIME.from_path(path))
    |> send_file(200, full_path(path))
    |> halt()
  end

  @impl true
  def open_file(path) do
    File.open(full_path(path), [:binary, :read])
  end

  @impl true
  def open_file(path, nil) do
    open_file(path)
  end

  def open_file(path, function) do
    File.open(full_path(path), [:binary, :read], function)
  end

  @impl true
  def delete_file(path) do
    File.rm(full_path(path))
  end

  defp full_path(path), do: Path.join(base_path(), path)

  defp base_path do
    Keyword.get(config(), :path)
  end

  defp config do
    Application.get_env(:asciinema, __MODULE__)
  end
end
