defmodule Asciinema.Repo.Migrations.AddStreamRecordingEnabledToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stream_recording_enabled, :boolean, default: true, null: false
    end
  end
end
