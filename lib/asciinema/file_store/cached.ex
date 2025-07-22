defmodule Asciinema.FileStore.Cached do
  use Asciinema.Config
  use Asciinema.FileStore

  @impl true
  def url(path) do
    remote_store().url(path)
  end

  @impl true
  def put_file(dst_path, src_local_path, content_type) do
    with :ok <- remote_store().put_file(dst_path, src_local_path, content_type) do
      cache_store().put_file(dst_path, src_local_path, content_type)
    end
  end

  @impl true
  def move_file(from_path, to_path) do
    with :ok <- remote_store().move_file(from_path, to_path) do
      cache_store().delete_file(from_path)

      :ok
    end
  end

  @impl true
  def serve_file(conn, path, filename) do
    remote_store().serve_file(conn, path, filename)
  end

  @impl true
  def open_file(path, function \\ nil) do
    case cache_store().open_file(path, function) do
      {:ok, f} ->
        {:ok, f}

      {:error, :enoent} ->
        with {:ok, tmp_path} <- Briefly.create(),
             :ok <- remote_store().download_file(path, tmp_path),
             :ok <- cache_store().put_file(path, tmp_path, MIME.from_path(path)),
             :ok <- File.rm(tmp_path) do
          cache_store().open_file(path, function)
        end

      otherwise ->
        otherwise
    end
  end

  @impl true
  def delete_file(path) do
    with result when result in [:ok, {:error, :enoent}] <- cache_store().delete_file(path) do
      remote_store().delete_file(path)
    end
  end

  defp remote_store, do: config(:remote_store)

  defp cache_store, do: config(:cache_store)
end
