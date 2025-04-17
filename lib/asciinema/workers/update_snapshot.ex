defmodule Asciinema.Workers.UpdateSnapshot do
  use Oban.Worker,
    unique: [
      period: :infinity,
      states: [:available, :retryable]
    ]

  alias Asciinema.Recordings
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"asciicast_id" => id}}) do
    Logger.info("updating snapshot for recording #{id}...")

    with {:ok, asciicast} <- Recordings.fetch_asciicast(id),
         {:ok, _} <- Recordings.update_snapshot(asciicast) do
      Logger.info("snapshot for recording #{id} updated")

      :ok
    else
      {:error, :not_found} -> :discard
      {:error, _} = result -> result
      result -> {:error, result}
    end
  end
end
