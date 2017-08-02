defmodule Asciinema.Asciicasts.SnapshotUpdater.Sync do
  alias Asciinema.Asciicasts
  alias Asciinema.Asciicasts.Asciicast

  def update_snapshot(%Asciicast{} = asciicast) do
    {:ok, _} = Asciicasts.update_snapshot(asciicast)
    :ok
  end
end
