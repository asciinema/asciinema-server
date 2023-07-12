defmodule Asciinema.Repo.Migrations.AddStartedAtToLiveStreams do
  use Ecto.Migration

  def change do
    alter table(:live_streams) do
      add :last_started_at, :naive_datetime
    end

    create index(:live_streams, :last_started_at)
  end
end
