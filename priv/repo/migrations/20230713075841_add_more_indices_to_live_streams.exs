defmodule Asciinema.Repo.Migrations.AddMoreIndicesToLiveStreams do
  use Ecto.Migration

  def change do
    create index(:live_streams, [:inserted_at])
  end
end
