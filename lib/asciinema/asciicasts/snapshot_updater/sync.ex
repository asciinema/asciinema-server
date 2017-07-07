defmodule Asciinema.Asciicasts.SnapshotUpdater.Sync do
  alias Asciinema.{Asciicast, Asciicasts}

  def update_snapshot(%Asciicast{} = asciicast) do
    {:ok, _} = Asciicasts.update_snapshot(asciicast)
    :ok
  end
end
