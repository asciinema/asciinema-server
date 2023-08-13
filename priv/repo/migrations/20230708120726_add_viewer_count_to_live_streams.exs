defmodule Asciinema.Repo.Migrations.AddViewerCountToLiveStreams do
  use Ecto.Migration

  def change do
    alter table(:live_streams) do
      add :current_viewer_count, :integer
      add :peak_viewer_count, :integer
    end

    create index(:live_streams, [:current_viewer_count])
    create index(:live_streams, [:peak_viewer_count])
  end
end
