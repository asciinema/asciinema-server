defmodule Asciinema.FileStore do
  @doc "Serves file at given path in store"
  @callback serve_file(conn :: %Plug.Conn{}, path :: String.t, filename :: String.t) :: %Plug.Conn{}
end
