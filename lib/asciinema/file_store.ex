defmodule Asciinema.FileStore do
  @doc "Serves file at given path in store"
  @callback serve_file(conn :: %Plug.Conn{}, path :: String.t, filename :: String.t) :: %Plug.Conn{}

  @doc "Opens the given path in store"
  @callback open(path :: String.t) :: {:ok, File.io_device} | {:error, File.posix}

  @doc "Opens the given path in store, executes given fn and closes the file"
  @callback open(path :: String.t, function :: (File.io_device -> res)) :: {:ok, res} | {:error, File.posix} when res: var
end
