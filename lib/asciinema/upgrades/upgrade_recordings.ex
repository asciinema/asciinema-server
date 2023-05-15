defmodule Asciinema.Upgrades.UpgradeRecordings do
  use Asciinema.Upgrades.Worker
  require Logger
  alias Asciinema.Recordings

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    Recordings.upgrade(id)
    Logger.info("recording #{id} upgraded")

    :ok
  end

  def perform(_job) do
    for recording <- Recordings.upgradable() do
      Oban.insert!(__MODULE__.new(%{id: recording.id}))
    end

    Logger.info("enqueued recording upgrade jobs")

    :ok
  end
end
