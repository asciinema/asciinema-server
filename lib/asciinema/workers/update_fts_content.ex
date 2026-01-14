defmodule Asciinema.Workers.UpdateFtsContent do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Asciinema.Recordings
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"asciicast_id" => id}}) do
    Logger.info("generating FTS content for recording #{id}...")

    with {:ok, asciicast} <- Recordings.fetch_asciicast(id),
         :ok <- Recordings.update_fts_content(asciicast) do
      Logger.info("FTS content for recording #{id} generated")

      :ok
    else
      {:error, :not_found} -> :discard
      {:error, _} = result -> result
      result -> {:error, result}
    end
  end
end
