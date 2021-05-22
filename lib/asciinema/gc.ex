defmodule Asciinema.GC do
  use Oban.Worker
  alias Asciinema.Accounts
  alias Asciinema.Asciicasts
  require Logger

  @impl Oban.Worker
  def perform(_job) do
    if days = Asciicasts.gc_days() do
      Logger.info("archiving unclaimed asciicasts...")
      dt = Timex.shift(Timex.now(), days: -days)
      count = Asciicasts.archive_asciicasts(Accounts.temporary_users(), dt)
      Logger.info("archived #{count} asciicasts")

      :ok
    else
      :discard
    end
  end
end
