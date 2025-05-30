defmodule Asciinema.Recordings.Asciicast.V3 do
  alias Asciinema.Colors
  alias Asciinema.Recordings.EventStream

  defmodule Writer do
    @enforce_keys [:file, :prev_time]
    defstruct [:file, :prev_time]
  end

  def event_stream(path) when is_binary(path) do
    [header_line] =
      path
      |> File.stream!([], :line)
      |> Stream.take(1)
      |> Enum.to_list()

    "{" <> _ = header_line
    header = Jason.decode!(header_line)
    3 = header["version"]

    path
    |> File.stream!([], :line)
    |> Stream.drop(1)
    |> Stream.reject(fn line -> line == "\n" or String.starts_with?(line, "#") end)
    |> Stream.map(&Jason.decode!/1)
    |> Stream.map(fn [time, code, data] -> {time, code, data} end)
    |> EventStream.cap_relative_time(header["idle_time_limit"])
    |> EventStream.to_absolute_time()
  end

  def fetch_metadata(path) do
    with {:ok, line} when is_binary(line) <- File.open(path, fn f -> IO.read(f, :line) end),
         {:ok, %{"version" => 3} = header} <- Jason.decode(line) do
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
        duration: get_duration(path),
        recorded_at: header["timestamp"] && Timex.from_unix(header["timestamp"]),
        title: header["title"],
        env: header["env"] || %{},
        idle_time_limit: header["idle_time_limit"],
        shell: get_in(header, ["env", "SHELL"])
      }

      {:ok, metadata}
    else
      {:ok, %{"version" => version}} ->
        {:error, {:invalid_version, version}}

      {:error, %Jason.DecodeError{}} ->
        {:error, :invalid_format}
    end
  end

  defp get_duration(path) do
    path
    |> event_stream()
    |> Enum.reduce(fn {t, _, _}, _prev_t -> t end)
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
      {:ok, %Writer{file: file, prev_time: 0}}
    end
  end

  def write_event(%Writer{file: file} = writer, time, type, data)
      when type in ["o", "i", "m", "x"] do
    rel_time = format_time(time - writer.prev_time)
    data = Jason.encode!(data)
    event = "[#{rel_time}, \"#{type}\", #{data}]"

    with :ok <- IO.write(file, event <> "\n") do
      {:ok, %{writer | prev_time: time}}
    end
  end

  def write_event(%Writer{file: file} = writer, time, "r", {cols, rows}) do
    rel_time = format_time(time - writer.prev_time)
    data = Jason.encode!("#{cols}x#{rows}")
    event = "[#{rel_time}, \"r\", #{data}]"

    with :ok <- IO.write(file, event <> "\n") do
      {:ok, %{writer | prev_time: time}}
    end
  end

  defp format_theme(nil), do: nil

  defp format_theme(theme) do
    palette =
      theme.palette
      |> Enum.map(&Colors.hex/1)
      |> Enum.join(":")

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
      |> String.trim_trailing("0")

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
