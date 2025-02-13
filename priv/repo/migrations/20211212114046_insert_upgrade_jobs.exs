defmodule Asciinema.Repo.Migrations.InsertUpgradeJobs do
  use Ecto.Migration
  alias Asciinema.Workers.InitialSeed

  def up do
    %{}
    |> Oban.Job.new(worker: InitialSeed)
    |> Oban.insert!()

    :ok
  end

  def down, do: :ok
end
