defmodule Asciinema.GC do
  use Oban.Worker
  alias Asciinema.Accounts
  alias Asciinema.Recordings
  require Logger

  @impl Oban.Worker
  def perform(_job) do
    if days = Recordings.gc_days() do
      Logger.info("archiving unclaimed Recordings...")
      dt = Timex.shift(Timex.now(), days: -days)
      count = Recordings.archive_asciicasts(Accounts.temporary_users(), dt)
      Logger.info("archived #{count} asciicasts")

      :ok
    else
      :discard
    end
  end
end
