defmodule Asciinema.GC do
  use Oban.Worker
  require Logger

  @impl Oban.Worker
  def perform(_job) do
    if days = Asciinema.recording_gc_days() do
      count = Asciinema.archive_unclaimed_recordings(days)

      if count > 0 do
        Logger.info("archived #{count} recordings")
      end

      :ok
    else
      :discard
    end
  end
end
