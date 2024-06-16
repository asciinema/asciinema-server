defmodule Asciinema.FileStore do
  @doc "Returns direct download URL for given path"
  @callback url(path :: String.t()) :: String.t() | nil

  @doc "Puts file at given path in store"
  @callback put_file(
              dst_path :: String.t(),
              src_local_path :: String.t(),
              content_type :: String.t()
            ) :: :ok | {:error, term}

  @doc "Moves file to a new path"
  @callback move_file(from_path :: Path.t(), to_path :: Path.t()) :: :ok | {:error, term}

  @doc "Serves file at given path in store"
  @callback serve_file(conn :: %Plug.Conn{}, path :: String.t(), filename :: String.t()) ::
              %Plug.Conn{}

  @doc "Opens the given path in store"
  @callback open_file(path :: String.t()) :: {:ok, File.io_device()} | {:error, File.posix()}

  @doc "Opens the given path in store, executes given fn and closes the file"
  @callback open_file(path :: String.t(), function :: (File.io_device() -> res)) ::
              {:ok, res} | {:error, File.posix()}
            when res: var

  @doc "Downloads file from given path in store to local path"
  @callback download_file(path :: String.t(), local_path :: String.t()) :: :ok | {:error, term}

  @doc "Deletes file"
  @callback delete_file(path :: String.t()) :: :ok | {:error, term}

  defmacro __using__(_) do
    quote do
      @behaviour Asciinema.FileStore

      def download_file(store_path, local_path) do
        with {:ok, {:ok, _}} <- open_file(store_path, &:file.copy(&1, local_path)) do
          :ok
        end
      end
    end
  end

  # Shortcuts

  def url(path) do
    adapter().url(path)
  end

  def put_file(dst_path, src_local_path, content_type) do
    adapter().put_file(dst_path, src_local_path, content_type)
  end

  def move_file(from_path, to_path) do
    adapter().move_file(from_path, to_path)
  end

  def open_file(path, f) do
    adapter().open_file(path, f)
  end

  def download_file(store_path, local_path) do
    adapter().download_file(store_path, local_path)
  end

  def delete_file(path) do
    adapter().delete_file(path)
  end

  def serve_file(conn, path, filename) do
    adapter().serve_file(conn, path, filename)
  end

  defp adapter do
    Keyword.fetch!(Application.get_env(:asciinema, __MODULE__), :adapter)
  end
end
