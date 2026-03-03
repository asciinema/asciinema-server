defmodule Asciinema.Gzip do
  alias __MODULE__.Stream

  defmodule Stream do
    @enforce_keys [:path, :chunk_size]
    defstruct [:path, :chunk_size]
  end

  @spec stream!(Path.t(), pos_integer()) :: Stream.t()
  def stream!(path, chunk_size)
      when is_binary(path) and is_integer(chunk_size) and chunk_size > 0 do
    %Stream{path: path, chunk_size: chunk_size}
  end

  def stream!(path, _chunk_size) when not is_binary(path) do
    raise ArgumentError, "expected path to be a binary, got: #{inspect(path)}"
  end

  def stream!(_path, chunk_size) do
    raise ArgumentError,
          "expected chunk_size to be a positive integer, got: #{inspect(chunk_size)}"
  end

  def reader_resource(%Stream{} = stream) do
    Elixir.Stream.resource(
      fn -> open_reader!(stream) end,
      &next_chunk/1,
      &close_reader/1
    )
  end

  def open_writer!(%Stream{path: path}) do
    case File.open(path, [:write, :binary]) do
      {:ok, file} ->
        deflater = :zlib.open()

        try do
          :ok = :zlib.deflateInit(deflater, :default, :deflated, 31, 8, :default)
          %{path: path, file: file, deflater: deflater}
        catch
          :error, reason ->
            :zlib.close(deflater)
            File.close(file)

            raise RuntimeError,
                  "failed to initialize gzip deflater for #{path}: #{inspect(reason)}"
        end

      {:error, reason} ->
        raise File.Error, reason: reason, action: "open file", path: path
    end
  end

  def collect_chunk(state, {:cont, data}) do
    compressed = deflate!(state.deflater, data, :none, state.path)
    write_chunk!(state.file, compressed, state.path)
    state
  end

  def collect_chunk(state, :done) do
    compressed = deflate!(state.deflater, <<>>, :finish, state.path)
    write_chunk!(state.file, compressed, state.path)
    close_writer(state)
  end

  def collect_chunk(state, :halt) do
    close_writer(state)
  end

  defp open_reader!(%Stream{path: path, chunk_size: chunk_size}) do
    case File.open(path, [:read, :binary]) do
      {:ok, file} ->
        inflater = :zlib.open()

        try do
          :ok = :zlib.inflateInit(inflater, 31)
          %{path: path, chunk_size: chunk_size, file: file, inflater: inflater, eof?: false}
        catch
          :error, reason ->
            :zlib.close(inflater)
            File.close(file)

            raise RuntimeError,
                  "failed to initialize gzip inflater for #{path}: #{inspect(reason)}"
        end

      {:error, reason} ->
        raise File.Error, reason: reason, action: "open file", path: path
    end
  end

  defp next_chunk(%{eof?: true} = state), do: {:halt, state}

  defp next_chunk(state) do
    case IO.binread(state.file, state.chunk_size) do
      :eof ->
        decompressed = inflate!(state.inflater, <<>>, state.path)
        state = %{state | eof?: true}

        if decompressed == <<>> do
          {:halt, state}
        else
          {[decompressed], state}
        end

      {:error, reason} ->
        raise File.Error, reason: reason, action: "read file", path: state.path

      compressed when is_binary(compressed) ->
        decompressed = inflate!(state.inflater, compressed, state.path)

        if decompressed == <<>> do
          {[], state}
        else
          {[decompressed], state}
        end
    end
  end

  defp close_reader(state) do
    safe_inflate_end(state.inflater)
    :zlib.close(state.inflater)
    File.close(state.file)
    :ok
  end

  defp close_writer(state) do
    safe_deflate_end(state.deflater)
    :zlib.close(state.deflater)
    File.close(state.file)
    :ok
  end

  defp inflate!(inflater, data, path) do
    try do
      inflater
      |> :zlib.inflate(data)
      |> IO.iodata_to_binary()
    catch
      :error, reason ->
        raise RuntimeError, "failed to inflate gzip stream #{path}: #{inspect(reason)}"
    end
  end

  defp deflate!(deflater, data, flush, path) do
    try do
      :zlib.deflate(deflater, data, flush)
    catch
      :error, reason ->
        raise RuntimeError, "failed to deflate gzip stream #{path}: #{inspect(reason)}"
    end
  end

  defp write_chunk!(_file, <<>>, _path), do: :ok
  defp write_chunk!(_file, [], _path), do: :ok

  defp write_chunk!(file, data, path) do
    case IO.binwrite(file, data) do
      :ok ->
        :ok

      {:error, reason} ->
        raise File.Error, reason: reason, action: "write file", path: path
    end
  catch
    :error, reason ->
      raise File.Error, reason: reason, action: "write file", path: path
  end

  defp safe_inflate_end(inflater) do
    try do
      :zlib.inflateEnd(inflater)
    catch
      _, _ -> :ok
    end
  end

  defp safe_deflate_end(deflater) do
    try do
      :zlib.deflateEnd(deflater)
    catch
      _, _ -> :ok
    end
  end
end

defimpl Enumerable, for: Asciinema.Gzip.Stream do
  def reduce(stream, acc, fun) do
    stream
    |> Asciinema.Gzip.reader_resource()
    |> Enumerable.reduce(acc, fun)
  end

  def count(_stream), do: {:error, __MODULE__}
  def member?(_stream, _value), do: {:error, __MODULE__}
  def slice(_stream), do: {:error, __MODULE__}
end

defimpl Collectable, for: Asciinema.Gzip.Stream do
  def into(stream) do
    state = Asciinema.Gzip.open_writer!(stream)
    {state, &Asciinema.Gzip.collect_chunk/2}
  end
end
