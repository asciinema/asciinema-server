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

  @doc "Returns local filesystem path for a given store path"
  @callback get_local_path(path :: String.t()) :: {:ok, String.t()} | {:error, term}

  @doc "Deletes file"
  @callback delete_file(path :: String.t()) :: :ok | {:error, term}

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

  def get_local_path(path) do
    adapter().get_local_path(path)
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
