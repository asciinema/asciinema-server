defmodule Asciinema.Asciicasts.SnapshotUpdater.Noop do
  def update_snapshot(_asciicast) do
    :ok
  end
end
