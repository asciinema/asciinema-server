defmodule Asciinema.Upgrades.InitialSeed do
  use Asciinema.Upgrades.Worker
  require Logger

  @impl Oban.Worker
  def perform(_job) do
    user = Asciinema.Accounts.ensure_asciinema_user()
    :ok = Asciinema.Asciicasts.ensure_welcome_asciicast(user)

    Logger.info("database seeded successfully")

    :ok
  end
end
