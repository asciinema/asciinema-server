defmodule Asciinema.Repo.Migrations.AddParserToLiveStreams do
  use Ecto.Migration

  def change do
    alter table(:live_streams) do
      add :parser, :string
    end

    create index(:live_streams, [:parser])
  end
end
