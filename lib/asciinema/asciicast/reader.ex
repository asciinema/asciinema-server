defmodule Asciinema.Asciicast.Reader do
  alias Asciinema.Zstd

  @chunk_size 64 * 1024

  @spec read_iodata!(Path.t(), keyword()) :: iodata()
  def read_iodata!(path, opts \\ []) when is_binary(path) and is_list(opts) do
    if compressed?(path, opts) do
      Enum.to_list(Zstd.stream!(path, @chunk_size))
    else
      [File.read!(path)]
    end
  end

  @spec stream_lines!(Path.t(), keyword()) :: Enumerable.t()
  def stream_lines!(path, opts \\ []) when is_binary(path) and is_list(opts) do
    if compressed?(path, opts) do
      Zstd.stream!(path, :line)
    else
      File.stream!(path, :line)
    end
  end

  @spec compressed?(Path.t(), keyword()) :: boolean()
  def compressed?(path, opts \\ []) when is_binary(path) and is_list(opts) do
    Keyword.get_lazy(opts, :compressed, fn -> compressed_file?(path) end)
  end

  defp compressed_file?(path) do
    case File.open(path, [:read, :binary], fn file -> IO.binread(file, 4) end) do
      {:ok, <<0x28, 0xB5, 0x2F, 0xFD>>} -> true
      {:ok, <<0x1F, 0x8B, _::binary-size(2)>>} -> true
      {:ok, _} -> false
      {:error, reason} -> raise File.Error, reason: reason, action: "open file", path: path
    end
  end
end
