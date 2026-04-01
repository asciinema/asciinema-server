defmodule Asciinema.Workers.CompressRecording do
  use Oban.Worker,
    queue: :maintenance,
    unique: [period: :infinity, states: :incomplete]

  alias Asciinema.Recordings
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"asciicast_id" => id}}) do
    Logger.info("compressing recording #{id}...")

    with {:ok, asciicast} <- Recordings.fetch_asciicast(id),
         {:ok, _asciicast} <- Recordings.compress_asciicast(asciicast) do
      Logger.info("recording #{id} compressed")
      :ok
    else
      {:error, :not_found} -> :discard
      {:error, _} = result -> result
      result -> {:error, result}
    end
  end
end
