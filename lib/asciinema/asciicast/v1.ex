defmodule Asciinema.Asciicast.V1 do
  alias Asciinema.Asciicast.{EventStream, Reader}

  def event_stream(path, opts \\ []) when is_binary(path) and is_list(opts) do
    asciicast =
      path
      |> Reader.read_iodata!(opts)
      |> Jason.decode!()

    1 = asciicast["version"]

    asciicast
    |> Map.fetch!("stdout")
    |> Stream.map(&parse_event/1)
    |> EventStream.to_absolute_time()
  end

  defp parse_event([time, data]) when is_number(time) and time >= 0 and is_binary(data) do
    {time, "o", data}
  end

  def fetch_metadata(path, opts \\ []) when is_binary(path) and is_list(opts) do
    with {:ok, attrs} <- parse_file(path, opts),
         {:ok, duration} <- get_duration(path, opts) do
      metadata = %{
        version: 1,
        term_cols: attrs["width"],
        term_rows: attrs["height"],
        term_type: get_in(attrs, ["env", "TERM"]),
        command: attrs["command"],
        duration: duration,
        title: attrs["title"],
        shell: get_in(attrs, ["env", "SHELL"]),
        env: attrs["env"] || %{}
      }

      {:ok, metadata}
    end
  end

  defp parse_file(path, opts) do
    json = Reader.read_iodata!(path, opts)

    with {:ok, %{"version" => 1} = attrs} <- Jason.decode(json) do
      {:ok, attrs}
    else
      {:ok, %{"version" => version}} ->
        {:error, {:invalid_version, version}}

      {:error, %Jason.DecodeError{}} ->
        {:error, :invalid_format}
    end
  end

  defp get_duration(path, opts) do
    duration =
      path
      |> event_stream(opts)
      |> Enum.reduce(0, fn {t, _, _}, _prev_t -> t end)

    # ensure a float: event times may be integers, and a recording with no
    # events reduces to the integer accumulator
    {:ok, duration / 1}
  rescue
    FunctionClauseError ->
      {:error, :invalid_format}
  end
end
