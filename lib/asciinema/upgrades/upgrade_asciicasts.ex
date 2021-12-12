defmodule Asciinema.Upgrades.UpgradeAsciicasts do
  use Asciinema.Upgrades.Worker
  require Logger
  alias Asciinema.Asciicasts

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    Asciicasts.upgrade(id)
    Logger.info("asciicast #{id} upgraded")

    :ok
  end

  def perform(_job) do
    for asciicast <- Asciicasts.upgradable() do
      Oban.insert!(__MODULE__.new(%{id: asciicast.id}))
    end

    Logger.info("enqueued asciicast upgrade jobs")

    :ok
  end
end
