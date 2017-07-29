defmodule Asciinema.Asciicasts.SnapshotUpdater do
  alias Asciinema.Asciicasts.Asciicast

  @doc "Generates poster for given asciicast"
  @callback update_snapshot(asciicast :: %Asciicast{}) :: :ok | {:error, term}

  def update_snapshot(asciicast) do
    Application.get_env(:asciinema, :snapshot_updater).update_snapshot(asciicast)
  end
end
