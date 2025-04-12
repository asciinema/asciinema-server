defmodule Asciinema.Recordings.Asciicast.V2 do
  alias Asciinema.Colors
  alias Asciinema.Recordings.EventStream

  defmodule Writer do
    defstruct [:file]
  end

  def event_stream(path) when is_binary(path) do
    first_two_lines =
      path
      |> File.stream!([], :line)
      |> Stream.take(2)
      |> Enum.to_list()

    ["{" <> _ = header_line, "[" <> _] = first_two_lines
    header = Jason.decode!(header_line)
    2 = header["version"]

    path
    |> File.stream!([], :line)
    |> Stream.drop(1)
    |> Stream.reject(fn line -> line == "\n" end)
    |> Stream.map(&Jason.decode!/1)
    |> Stream.map(fn [time, code, data] -> {time, code, data} end)
    |> EventStream.to_relative_time()
    |> EventStream.cap_relative_time(header["idle_time_limit"])
    |> EventStream.to_absolute_time()
  end

  def fetch_metadata(path) do
    with {:ok, line} when is_binary(line) <- File.open(path, fn f -> IO.read(f, :line) end),
         {:ok, %{"version" => 2} = header} <- Jason.decode(line) do
      metadata = %{
        version: 2,
        term_cols: header["width"],
        term_rows: header["height"],
        term_type: get_in(header, ["env", "TERM"]),
        term_theme_fg: get_in(header, ["theme", "fg"]),
        term_theme_bg: get_in(header, ["theme", "bg"]),
        term_theme_palette: get_in(header, ["theme", "palette"]),
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
    term_theme = Keyword.get(fields, :term_theme)
    env = Keyword.get(fields, :env) || %{}

    header =
      [
        version: 2,
        width: cols,
        height: rows,
        timestamp: timestamp,
        env: drop_empty(env),
        theme: format_theme(term_theme)
      ]
      |> drop_empty()
      |> Jason.OrderedObject.new()

    with :ok <- IO.write(file, Jason.encode!(header) <> "\n") do
      {:ok, %Writer{file: file}}
    end
  end

  def write_event(%Writer{file: file} = writer, time, type, data) when type in ["o", "i", "m"] do
    time = format_time(time)
    data = Jason.encode!(data)
    event = "[#{time}, \"#{type}\", #{data}]"

    with :ok <- IO.write(file, event <> "\n") do
      {:ok, writer}
    end
  end

  def write_event(%Writer{file: file} = writer, time, "r", {cols, rows}) do
    time = format_time(time)
    data = Jason.encode!("#{cols}x#{rows}")
    event = "[#{time}, \"r\", #{data}]"

    with :ok <- IO.write(file, event <> "\n") do
      {:ok, writer}
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
