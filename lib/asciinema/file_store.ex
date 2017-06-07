defmodule Asciinema.FileStore do
  @doc "Puts file at given path in store"
  @callback put_file(dst_path :: String.t, src_local_path :: String.t, content_type :: String.t) :: :ok | {:error, term}

  @doc "Serves file at given path in store"
  @callback serve_file(conn :: %Plug.Conn{}, path :: String.t, filename :: String.t) :: %Plug.Conn{}

  @doc "Opens the given path in store"
  @callback open(path :: String.t) :: {:ok, File.io_device} | {:error, File.posix}

  @doc "Opens the given path in store, executes given fn and closes the file"
  @callback open(path :: String.t, function :: (File.io_device -> res)) :: {:ok, res} | {:error, File.posix} when res: var

  def put_file(dst_path, src_local_path, content_type) do
    Application.get_env(:asciinema, :file_store).put_file(dst_path, src_local_path, content_type)
  end
end
