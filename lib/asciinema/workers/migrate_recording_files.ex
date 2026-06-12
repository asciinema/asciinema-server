defmodule Asciinema.Workers.MigrateRecordingFiles do
  use Oban.Worker,
    unique: [
      period: :infinity,
      states: [:available, :retryable]
    ]

  require Logger
  alias Asciinema.Recordings
  alias Asciinema.Recordings.Query, as: RecordingQuery

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"asciicast_id" => id}}) do
    Logger.info("migrating file for recording #{id}...")
    Recordings.migrate_file(id)
    Logger.info("recording #{id} file migrated")

    :ok
  end

  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    asciicasts =
      %RecordingQuery{scope: :system, filters: [{:user, user_id}]}
      |> Recordings.stream()
      |> Recordings.migratable()

    Enum.each(asciicasts, fn asciicast ->
      Oban.insert!(__MODULE__.new(%{asciicast_id: asciicast.id}))
    end)

    :ok
  end

  def perform(_job) do
    asciicasts =
      %RecordingQuery{scope: :system}
      |> Recordings.stream()
      |> Recordings.migratable()

    Enum.each(asciicasts, fn asciicast ->
      Oban.insert!(__MODULE__.new(%{asciicast_id: asciicast.id}))
    end)

    :ok
  end
end
