defmodule Asciinema.Zstd do
  alias __MODULE__.Stream

  @read_chunk_size 64 * 1024

  defmodule Stream do
    @enforce_keys [:path, :mode]
    defstruct [:path, :mode, :chunk_size, writer_opts: []]
  end

  @spec stream!(Path.t(), pos_integer()) :: Stream.t()
  def stream!(path, chunk_size), do: stream!(path, chunk_size, [])

  @spec stream!(Path.t(), pos_integer(), keyword()) :: Stream.t()
  def stream!(path, chunk_size, opts)
      when is_binary(path) and is_integer(chunk_size) and chunk_size > 0 and is_list(opts) do
    opts = Keyword.validate!(opts, [:compression_level])
    %Stream{path: path, mode: :bytes, chunk_size: chunk_size, writer_opts: opts}
  end

  @spec stream!(Path.t(), :line) :: Stream.t()
  def stream!(path, :line, []) when is_binary(path) do
    %Stream{path: path, mode: :line, chunk_size: @read_chunk_size}
  end

  def stream!(path, :line, opts) when is_binary(path) and is_list(opts) do
    raise ArgumentError, "opts are not supported in :line mode, got: #{inspect(opts)}"
  end

  def stream!(path, _chunk_size, _opts) when not is_binary(path) do
    raise ArgumentError, "expected path to be a binary, got: #{inspect(path)}"
  end

  def stream!(_path, _chunk_size, opts) when not is_list(opts) do
    raise ArgumentError, "expected opts to be a keyword list, got: #{inspect(opts)}"
  end

  def stream!(_path, chunk_size, _opts) do
    raise ArgumentError,
          "expected chunk_size to be a positive integer or :line, got: #{inspect(chunk_size)}"
  end

  def reader_resource(%Stream{} = stream) do
    Elixir.Stream.resource(
      fn -> open_reader!(stream) end,
      &next_item/1,
      &close_reader/1
    )
  end

  def open_writer!(%Stream{path: path, writer_opts: writer_opts}) do
    case File.open(path, [:write, :binary]) do
      {:ok, file} ->
        case :zstd.context(:compress, compression_options(writer_opts)) do
          {:ok, context} ->
            %{path: path, file: file, context: context}

          {:error, reason} ->
            File.close(file)

            raise RuntimeError,
                  "failed to initialize zstd compressor for #{path}: #{inspect(reason)}"
        end

      {:error, reason} ->
        raise File.Error, reason: reason, action: "open file", path: path
    end
  end

  def collect_chunk(state, {:cont, data}) do
    compressed = stream!(state.context, data, state.path, :compress)
    write_chunk!(state.file, compressed, state.path)
    state
  end

  def collect_chunk(state, :done) do
    compressed = finish!(state.context, <<>>, state.path, :compress)
    write_chunk!(state.file, compressed, state.path)
    close_writer(state)
  end

  def collect_chunk(state, :halt) do
    close_writer(state)
  end

  defp open_reader!(%Stream{path: path, chunk_size: chunk_size, mode: mode}) do
    case File.open(path, [:read, :binary]) do
      {:ok, file} ->
        case :zstd.context(:decompress) do
          {:ok, context} ->
            %{
              path: path,
              mode: mode,
              chunk_size: chunk_size,
              file: file,
              context: context,
              eof?: false,
              buffer: <<>>
            }

          {:error, reason} ->
            File.close(file)

            raise RuntimeError,
                  "failed to initialize zstd decompressor for #{path}: #{inspect(reason)}"
        end

      {:error, reason} ->
        raise File.Error, reason: reason, action: "open file", path: path
    end
  end

  defp next_item(%{mode: :bytes} = state), do: next_chunk(state)
  defp next_item(%{mode: :line} = state), do: next_line(state)

  defp next_chunk(%{eof?: true} = state), do: {:halt, state}

  defp next_chunk(state) do
    {decompressed, state} = decompress_more(state)

    if decompressed == <<>> do
      if state.eof?, do: {:halt, state}, else: {[], state}
    else
      {[decompressed], state}
    end
  end

  defp next_line(state) do
    case extract_lines(state.buffer, state.eof?) do
      {:emit, lines, buffer} ->
        {lines, %{state | buffer: buffer}}

      :need_more ->
        case decompress_more(state) do
          {<<>>, %{eof?: false} = state} ->
            {[], state}

          {decompressed, state} ->
            next_line(%{state | buffer: state.buffer <> decompressed})
        end

      :halt ->
        {:halt, state}
    end
  end

  defp decompress_more(%{eof?: true} = state), do: {<<>>, state}

  defp decompress_more(state) do
    case IO.binread(state.file, state.chunk_size) do
      :eof ->
        decompressed = finish!(state.context, <<>>, state.path, :decompress)
        {decompressed, %{state | eof?: true}}

      {:error, reason} ->
        raise File.Error, reason: reason, action: "read file", path: state.path

      compressed when is_binary(compressed) ->
        decompressed = stream!(state.context, compressed, state.path, :decompress)
        {decompressed, state}
    end
  end

  defp extract_lines(<<>>, true), do: :halt

  defp extract_lines(buffer, eof?) do
    case :binary.matches(buffer, "\n") do
      [] when eof? ->
        {:emit, [buffer], <<>>}

      [] ->
        :need_more

      newline_positions ->
        {lines, start} =
          Enum.reduce(newline_positions, {[], 0}, fn {index, 1}, {lines, start} ->
            line = :binary.part(buffer, start, index + 1 - start)
            {[line | lines], index + 1}
          end)

        lines = Enum.reverse(lines)
        rest = :binary.part(buffer, start, byte_size(buffer) - start)

        if eof? and rest != <<>> do
          {:emit, lines ++ [rest], <<>>}
        else
          {:emit, lines, rest}
        end
    end
  end

  defp close_reader(state) do
    safe_close(state.context)
    File.close(state.file)
    :ok
  end

  defp close_writer(state) do
    safe_close(state.context)
    File.close(state.file)
    :ok
  end

  defp stream!(context, data, path, operation) do
    try do
      case :zstd.stream(context, data) do
        {status, output} when status in [:continue, :done] ->
          IO.iodata_to_binary(output)

        {status, rest, output} when status in [:continue, :done] ->
          IO.iodata_to_binary([output, stream!(context, rest, path, operation)])
      end
    catch
      :error, reason ->
        raise RuntimeError, "failed to #{operation} zstd stream #{path}: #{inspect(reason)}"
    end
  end

  defp finish!(context, data, path, operation) do
    try do
      case :zstd.finish(context, data) do
        {status, output} when status in [:continue, :done] ->
          IO.iodata_to_binary(output)
      end
    catch
      :error, reason ->
        raise RuntimeError, "failed to #{operation} zstd stream #{path}: #{inspect(reason)}"
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

  defp safe_close(context) do
    try do
      :zstd.close(context)
    catch
      _, _ -> :ok
    end
  end

  def compress_file(input_path), do: compress_file(input_path, nil, [])

  def compress_file(input_path, opts) when is_list(opts), do: compress_file(input_path, nil, opts)

  def compress_file(input_path, output_path), do: compress_file(input_path, output_path, [])

  def compress_file(input_path, output_path, opts)
      when (is_binary(output_path) or is_nil(output_path)) and is_list(opts) do
    output_path = output_path || Briefly.create!()

    input_path
    |> File.stream!(@read_chunk_size)
    |> Enum.into(stream!(output_path, @read_chunk_size, opts))

    output_path
  end

  defp compression_options(opts) do
    case Keyword.fetch(opts, :compression_level) do
      {:ok, level} -> %{compressionLevel: level}
      :error -> %{}
    end
  end
end

defimpl Enumerable, for: Asciinema.Zstd.Stream do
  def reduce(stream, acc, fun) do
    stream
    |> Asciinema.Zstd.reader_resource()
    |> Enumerable.reduce(acc, fun)
  end

  def count(_stream), do: {:error, __MODULE__}
  def member?(_stream, _value), do: {:error, __MODULE__}
  def slice(_stream), do: {:error, __MODULE__}
end

defimpl Collectable, for: Asciinema.Zstd.Stream do
  def into(stream) do
    state = Asciinema.Zstd.open_writer!(stream)
    {state, &Asciinema.Zstd.collect_chunk/2}
  end
end
