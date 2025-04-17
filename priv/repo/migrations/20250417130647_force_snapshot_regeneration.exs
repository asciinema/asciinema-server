defmodule Asciinema.Repo.Migrations.ForceSnapshotRegeneration do
  use Ecto.Migration

  def up do
    execute "UPDATE asciicasts SET snapshot = NULL"

    %{}
    |> Oban.Job.new(worker: Asciinema.Workers.GenerateSnapshots)
    |> Asciinema.Repo.insert!()
  end

  def down, do: :ok
end
