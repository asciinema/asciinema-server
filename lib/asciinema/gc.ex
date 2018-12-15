defmodule Asciinema.GC do
  alias Asciinema.Accounts
  alias Asciinema.Asciicasts
  require Logger

  def run do
    if days = Asciicasts.gc_days() do
      Logger.info("archiving anonymous recordings...")
      dt = Timex.shift(Timex.now(), days: -days)
      count = Asciicasts.archive_asciicasts(Accounts.temporary_users(), dt)
      Logger.info("archived #{count} recordings")
    end
  end
end
