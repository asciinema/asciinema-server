defmodule Asciinema.Asciicasts.SnapshotUpdater.Exq do
  alias Asciinema.{Repo, Asciicasts}
  alias Asciinema.Asciicasts.Asciicast

  def update_snapshot(%Asciicast{id: id}) do
    {:ok, _jid} = Exq.enqueue(Exq, "default", __MODULE__, [id])
    :ok
  end

  def perform(asciicast_id) do
    if asciicast = Repo.get(Asciicast, asciicast_id) do
      {:ok, _} = Asciicasts.update_snapshot(asciicast)
    end
  end
end
