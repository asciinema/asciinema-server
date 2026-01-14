defmodule Asciinema.Repo.Migrations.AddOfflineGracePeriodToStreams do
  use Ecto.Migration

  def change do
    alter table(:streams) do
      add :offline_grace_period, :integer, default: 300, null: false
    end
  end
end
