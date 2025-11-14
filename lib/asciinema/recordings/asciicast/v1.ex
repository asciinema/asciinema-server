defmodule Asciinema.Recordings.Asciicast.V1 do
  alias Asciinema.Recordings.EventStream

  def event_stream(path) when is_binary(path) do
    asciicast =
      path
      |> File.read!()
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

  def fetch_metadata(path) do
    with {:ok, attrs} <- parse_file(path),
         {:ok, duration} <- get_duration(path) do
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

  defp parse_file(path) do
    with {:ok, json} <- File.read(path),
         {:ok, %{"version" => 1} = attrs} <- Jason.decode(json) do
      {:ok, attrs}
    else
      {:ok, %{"version" => version}} ->
        {:error, {:invalid_version, version}}

      {:error, %Jason.DecodeError{}} ->
        {:error, :invalid_format}
    end
  end

  defp get_duration(path) do
    duration =
      path
      |> event_stream()
      |> Enum.reduce(0, fn {t, _, _}, _prev_t -> t end)

    {:ok, duration}
  rescue
    FunctionClauseError ->
      {:error, :invalid_format}
  end
end
