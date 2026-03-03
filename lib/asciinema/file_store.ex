defmodule Asciinema.FileStore do
  @doc "Returns URI for a given path"
  @callback uri(path :: String.t()) :: String.t()

  @doc "Puts file at given path in store"
  @callback put_file(
              dst_path :: String.t(),
              src_local_path :: String.t(),
              content_type :: String.t()
            ) :: :ok | {:error, term}

  @doc "Moves file to a new path"
  @callback move_file(from_path :: Path.t(), to_path :: Path.t()) :: :ok | {:error, term}

  @doc "Deletes file"
  @callback delete_file(path :: String.t()) :: :ok | {:error, term}

  # Shortcuts

  def uri(path) do
    adapter().uri(path)
  end

  def put_file(dst_path, src_local_path, content_type) do
    adapter().put_file(dst_path, src_local_path, content_type)
  end

  def move_file(from_path, to_path) do
    adapter().move_file(from_path, to_path)
  end

  def delete_file(path) do
    adapter().delete_file(path)
  end

  defp adapter do
    Keyword.fetch!(Application.get_env(:asciinema, __MODULE__), :adapter)
  end
end
