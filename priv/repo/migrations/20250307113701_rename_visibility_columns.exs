defmodule Asciinema.Repo.Migrations.RenameVisibilityColumns do
  use Ecto.Migration

  def change do
    rename table(:users), :default_asciicast_visibility, to: :default_recording_visibility
    execute "ALTER TYPE live_stream_visibility RENAME TO stream_visibility", "ALTER TYPE stream_visibility RENAME TO live_stream_visibility"
    execute "ALTER TYPE asciicast_visibility RENAME TO recording_visibility", "ALTER TYPE recording_visibility RENAME TO asciicast_visibility"
  end
end
