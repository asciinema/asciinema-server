defmodule Asciinema.FileStore do
  @doc "Puts file at given path in store"
  @callback put_file(dst_path :: String.t, src_local_path :: String.t, content_type :: String.t, compress :: boolean) :: :ok | {:error, term}

  @doc "Serves file at given path in store"
  @callback serve_file(conn :: %Plug.Conn{}, path :: String.t, filename :: String.t) :: %Plug.Conn{}

  @doc "Opens the given path in store"
  @callback open_file(path :: String.t) :: {:ok, File.io_device} | {:error, File.posix}

  @doc "Opens the given path in store, executes given fn and closes the file"
  @callback open_file(path :: String.t, function :: (File.io_device -> res)) :: {:ok, res} | {:error, File.posix} when res: var

  @doc "Downloads file from given path in store to local path"
  @callback download_file(path :: String.t, local_path :: String.t) :: :ok | {:error, term}

  defmacro __using__(_) do
    quote do
      @behaviour Asciinema.FileStore

      def download_file(store_path, local_path) do
        case open_file(store_path, &(:file.copy(&1, local_path))) do
          {:ok, {:ok, _}} -> :ok
          otherwise -> otherwise
        end
      end
    end
  end

  # Shortcuts

  def put_file(dst_path, src_local_path, content_type, compress \\ false) do
    instance().put_file(dst_path, src_local_path, content_type, compress)
  end

  def open_file(path, f) do
    instance().open_file(path, f)
  end

  def download_file(store_path, local_path) do
    instance().download_file(store_path, local_path)
  end

  defp instance do
    Application.get_env(:asciinema, :file_store)
  end
end
