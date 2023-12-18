defmodule Asciinema.GC do
  use Oban.Worker
  require Logger

  @impl Oban.Worker
  def perform(_job) do
    hide_unclaimed_recordings(Asciinema.unclaimed_recording_ttl(:hide))
    delete_unclaimed_recordings(Asciinema.unclaimed_recording_ttl(:delete))

    :ok
  end

  defp hide_unclaimed_recordings(nil), do: :ok

  defp hide_unclaimed_recordings(days) do
    count = Asciinema.hide_unclaimed_recordings(days)

    if count > 0 do
      Logger.info("hid #{count} unclaimed recordings")
    end
  end

  defp delete_unclaimed_recordings(nil), do: :ok

  defp delete_unclaimed_recordings(days) do
    count = Asciinema.delete_unclaimed_recordings(days)

    if count > 0 do
      Logger.info("deleted #{count} unclaimed recordings")
    end
  end
end
