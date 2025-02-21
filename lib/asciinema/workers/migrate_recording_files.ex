defmodule Asciinema.Workers.MigrateRecordingFiles do
  use Oban.Worker,
    unique: [
      period: :infinity,
      states: [:available, :retryable]
    ]

  require Logger
  alias Asciinema.Recordings

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"asciicast_id" => id}}) do
    Logger.info("migrating file for recording #{id}...")
    Recordings.migrate_file(id)
    Logger.info("recording #{id} file migrated")

    :ok
  end

  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    for recording <- Recordings.stream_migratable_asciicasts(user_id) do
      Oban.insert!(__MODULE__.new(%{asciicast_id: recording.id}))
    end

    :ok
  end

  def perform(_job) do
    for recording <- Recordings.stream_migratable_asciicasts() do
      Oban.insert!(__MODULE__.new(%{asciicast_id: recording.id}))
    end

    :ok
  end
end
