defmodule Asciinema.Recordings.SnapshotUpdater.Sync do
  alias Asciinema.Recordings
  alias Asciinema.Recordings.Asciicast

  def update_snapshot(%Asciicast{} = asciicast) do
    {:ok, _} = Recordings.update_snapshot(asciicast)
    :ok
  end
end
