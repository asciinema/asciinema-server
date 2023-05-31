defmodule Asciinema.Recordings.SnapshotUpdater do
  defmodule Job do
    use Oban.Worker
    alias Asciinema.{Repo, Recordings}
    alias Asciinema.Recordings.Asciicast

    @impl Oban.Worker
    def perform(job) do
      if asciicast = Repo.get(Asciicast, job.args["asciicast_id"]) do
        Recordings.update_snapshot(asciicast)
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
