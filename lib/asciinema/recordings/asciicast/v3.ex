defmodule Asciinema.Recordings.Asciicast.V3 do
  alias Asciinema.Colors
  alias Asciinema.Quantizer
  alias Asciinema.Recordings.EventStream

  defmodule Writer do
    @enforce_keys [:file, :prev_time, :time_quantizer]
    defstruct [:file, :prev_time, :time_quantizer]
  end

  def event_stream(path) when is_binary(path) do
    ["{" <> _ = header_line] =
      path
      |> File.stream!([], :line)
      |> Stream.take(1)
      |> Enum.to_list()

    header = Jason.decode!(header_line)
    3 = header["version"]

    path
    |> File.stream!([], :line)
    |> Stream.drop(1)
    |> Stream.reject(fn line -> line == "\n" or String.starts_with?(line, "#") end)
    |> Stream.map(&Jason.decode!/1)
    |> Stream.flat_map(&parse_event/1)
    |> EventStream.cap_relative_time(header["idle_time_limit"])
    |> EventStream.to_absolute_time()
  end

  defp parse_event([time, "r", data]) when is_number(time) and time >= 0 and is_binary(data) do
    with [cols, rows] <- String.split(data, "x"),
         {cols, ""} when cols > 0 <- Integer.parse(cols),
         {rows, ""} when rows > 0 <- Integer.parse(rows) do
      [{time, "r", {cols, rows}}]
    else
      _ -> []
    end
  end

  defp parse_event([time, code, data])
       when is_number(time) and time >= 0 and is_binary(code) and is_binary(data) do
    [{time, code, data}]
  end

  def fetch_metadata(path) do
    with {:ok, header} <- parse_header(path),
         {:ok, duration} <- get_duration(path) do
      metadata = %{
        version: 3,
        term_cols: get_in(header, ["term", "cols"]),
        term_rows: get_in(header, ["term", "rows"]),
        term_type: get_in(header, ["term", "type"]),
        term_version: get_in(header, ["term", "version"]),
        term_theme_fg: get_in(header, ["term", "theme", "fg"]),
        term_theme_bg: get_in(header, ["term", "theme", "bg"]),
        term_theme_palette: get_in(header, ["term", "theme", "palette"]),
        command: header["command"],
        duration: duration,
        recorded_at: header["timestamp"] && Timex.from_unix(header["timestamp"]),
        title: header["title"],
        env: header["env"] || %{},
        idle_time_limit: header["idle_time_limit"],
        shell: get_in(header, ["env", "SHELL"])
      }

      {:ok, metadata}
    end
  end

  defp parse_header(path) do
    with {:ok, line} when is_binary(line) <- File.open(path, fn f -> IO.read(f, :line) end),
         {:ok, %{"version" => 3} = header} <- Jason.decode(line),
         :ok <- validate_theme(get_in(header, ["term", "theme"])) do
      {:ok, header}
    else
      {:ok, %{"version" => version}} ->
        {:error, {:invalid_version, version}}

      {:error, %Jason.DecodeError{}} ->
        {:error, :invalid_format}

      {:error, :invalid_theme} ->
        {:error, :invalid_format}
    end
  end

  defp validate_theme(nil), do: :ok

  defp validate_theme(%{"fg" => _, "bg" => _, "palette" => _}), do: :ok

  defp validate_theme(_theme), do: {:error, :invalid_theme}

  defp get_duration(path) do
    duration =
      path
      |> event_stream()
      |> Enum.reduce(0, fn {t, _, _}, _prev_t -> t end)

    {:ok, duration}
  rescue
    MatchError ->
      {:error, :invalid_format}

    FunctionClauseError ->
      {:error, :invalid_format}
  end

  def create(path, {cols, rows}, fields \\ []) do
    file = File.open!(path, [:write, :utf8])
    timestamp = Keyword.get(fields, :timestamp)
    title = Keyword.get(fields, :title)
    env = drop_empty(Keyword.get(fields, :env) || %{})

    term =
      [
        cols: cols,
        rows: rows,
        type: Keyword.get(fields, :term_type),
        version: Keyword.get(fields, :term_version),
        theme: format_theme(Keyword.get(fields, :term_theme))
      ]
      |> drop_empty()
      |> Jason.OrderedObject.new()

    header =
      [version: 3, term: term, timestamp: timestamp, title: title, env: env]
      |> drop_empty()
      |> Jason.OrderedObject.new()

    with :ok <- IO.write(file, Jason.encode!(header) <> "\n") do
      {:ok, %Writer{file: file, prev_time: 0, time_quantizer: Quantizer.new(1_000)}}
    end
  end

  def write_event(
        %Writer{} = writer,
        time,
        type,
        data
      )
      when type in ["o", "i", "m", "x"] do
    {time_quantizer, dt} = Quantizer.next(writer.time_quantizer, time - writer.prev_time)
    data = Jason.encode!(data)
    event = "[#{format_time(dt)}, \"#{type}\", #{data}]"

    with :ok <- IO.write(writer.file, event <> "\n") do
      {:ok, %{writer | prev_time: time, time_quantizer: time_quantizer}}
    end
  end

  def write_event(
        %Writer{} = writer,
        time,
        "r",
        {cols, rows}
      ) do
    {time_quantizer, dt} = Quantizer.next(writer.time_quantizer, time - writer.prev_time)
    data = Jason.encode!("#{cols}x#{rows}")
    event = "[#{format_time(dt)}, \"r\", #{data}]"

    with :ok <- IO.write(writer.file, event <> "\n") do
      {:ok, %{writer | prev_time: time, time_quantizer: time_quantizer}}
    end
  end

  defp format_theme(nil), do: nil

  defp format_theme(theme) do
    palette = Enum.map_join(theme.palette, ":", &Colors.hex/1)

    Jason.OrderedObject.new(
      fg: Colors.hex(theme.fg),
      bg: Colors.hex(theme.bg),
      palette: palette
    )
  end

  defp format_time(time) do
    whole = div(time, 1_000_000)

    decimal =
      time
      |> rem(1_000_000)
      |> to_string()
      |> String.pad_leading(6, "0")
      |> String.slice(0, 3)

    decimal =
      case decimal do
        "" -> "0"
        d -> d
      end

    "#{whole}.#{decimal}"
  end

  defp drop_empty(map) when is_map(map) do
    map
    |> Enum.filter(fn {_k, v} -> v != nil and v != "" and v != %{} end)
    |> Enum.into(%{})
  end

  defp drop_empty(kv) when is_list(kv) do
    Enum.filter(kv, fn {_k, v} -> v != nil and v != "" and v != %{} end)
  end

  def close(%Writer{file: file}), do: File.close(file)
end
