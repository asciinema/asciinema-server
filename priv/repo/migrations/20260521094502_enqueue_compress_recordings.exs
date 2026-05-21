defmodule Asciinema.Repo.Migrations.EnqueueCompressRecordings do
  use Ecto.Migration

  def change do
    execute(fn ->
      %{}
      |> Oban.Job.new(worker: Asciinema.Workers.CompressRecordings)
      |> Asciinema.Repo.insert!()
    end, "")
  end
end
