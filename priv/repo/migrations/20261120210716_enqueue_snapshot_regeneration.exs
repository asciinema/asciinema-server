defmodule Asciinema.Repo.Migrations.EnqueueSnapshotRegeneration do
  use Ecto.Migration

  def change do
    execute(fn ->
      %{all: true}
      |> Oban.Job.new(worker: Asciinema.Workers.GenerateSnapshots)
      |> Asciinema.Repo.insert!()
    end, "")
  end
end
