defmodule Asciinema.Repo.Migrations.AddOnlineToLiveStreams do
  use Ecto.Migration

  def change do
    alter table(:live_streams) do
      add :online, :boolean, null: false, default: false
    end

    create index(:live_streams, [:online])
  end
end
