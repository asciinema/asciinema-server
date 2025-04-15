defmodule Asciinema.Repo.Migrations.InsertUpgradeJobs do
  use Ecto.Migration

  def up do
    %{}
    |> Oban.Job.new(worker: Asciinema.Workers.InitialSeed)
    |> Asciinema.Repo.insert!()

    :ok
  end

  def down, do: :ok
end
