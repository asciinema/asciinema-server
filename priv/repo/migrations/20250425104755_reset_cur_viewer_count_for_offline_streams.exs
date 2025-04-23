defmodule Asciinema.Repo.Migrations.ResetCurViewerCountForOfflineStreams do
  use Ecto.Migration

  def up do
    execute "UPDATE streams SET current_viewer_count = 0 WHERE NOT online"
  end

  def down do
  end
end
