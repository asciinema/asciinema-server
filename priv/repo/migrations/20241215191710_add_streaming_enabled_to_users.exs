defmodule Asciinema.Repo.Migrations.AddStreamingEnabledToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :streaming_enabled, :boolean, default: true, null: false
    end
  end
end
