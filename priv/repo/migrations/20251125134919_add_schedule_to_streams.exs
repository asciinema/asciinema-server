defmodule Asciinema.Repo.Migrations.AddScheduleToStreams do
  use Ecto.Migration

  def change do
    alter table(:streams) do
      add :schedule, :map
      add :next_start_at, :utc_datetime
    end

    create index(:streams, [:next_start_at])
  end
end
