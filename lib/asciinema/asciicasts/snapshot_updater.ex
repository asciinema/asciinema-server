defmodule Asciinema.Asciicasts.SnapshotUpdater do
  defmodule Job do
    use Oban.Worker
    alias Asciinema.{Repo, Asciicasts}
    alias Asciinema.Asciicasts.Asciicast

    @impl Oban.Worker
    def perform(job) do
      if asciicast = Repo.get(Asciicast, job.args["asciicast_id"]) do
        Asciicasts.update_snapshot(asciicast)
      else
        :discard
      end
    end
  end

  def update_snapshot(asciicast) do
    with {:ok, _} <- Oban.insert(Job.new(%{asciicast_id: asciicast.id})) do
      :ok
    end
  end
end
