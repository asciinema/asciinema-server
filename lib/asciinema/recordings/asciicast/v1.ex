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
    |> Stream.map(fn [time, data] -> {time, "o", data} end)
    |> EventStream.to_absolute_time()
  end

  def fetch_metadata(path) do
    with {:ok, json} <- File.read(path),
         {:ok, %{"version" => 1} = attrs} <- Jason.decode(json) do
      metadata = %{
        version: 1,
        term_cols: attrs["width"],
        term_rows: attrs["height"],
        term_type: get_in(attrs, ["env", "TERM"]),
        command: attrs["command"],
        duration: attrs["duration"],
        title: attrs["title"],
        shell: get_in(attrs, ["env", "SHELL"]),
        env: attrs["env"] || %{}
      }

      {:ok, metadata}
    else
      {:ok, %{"version" => version}} ->
        {:error, {:invalid_version, version}}

      {:error, %Jason.DecodeError{}} ->
        {:error, :invalid_format}
    end
  end
end
