defmodule Asciinema.Recordings.SnapshotUpdater.Noop do
  def update_snapshot(_asciicast) do
    :ok
  end
end
