defmodule Asciinema.Repo.Migrations.AddMissingIndicesToLiveStreams do
  use Ecto.Migration

  def change do
    create index(:live_streams, [:user_id])
    create unique_index(:live_streams, [:producer_token])
  end
end
