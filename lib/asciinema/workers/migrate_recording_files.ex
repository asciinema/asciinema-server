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
    asciicasts =
      {:user_id, user_id}
      |> Recordings.query()
      |> Recordings.stream()
      |> Recordings.migratable()

    for asciicast <- asciicasts do
      Oban.insert!(__MODULE__.new(%{asciicast_id: asciicast.id}))
    end

    :ok
  end

  def perform(_job) do
    asciicasts =
      Recordings.query()
      |> Recordings.stream()
      |> Recordings.migratable()

    for asciicast <- asciicasts do
      Oban.insert!(__MODULE__.new(%{asciicast_id: asciicast.id}))
    end

    :ok
  end
end
