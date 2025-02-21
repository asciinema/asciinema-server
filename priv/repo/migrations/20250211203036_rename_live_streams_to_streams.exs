defmodule Asciinema.Repo.Migrations.RenameLiveStreamsToStreams do
  use Ecto.Migration

  def change do
    rename table(:live_streams), to: table(:streams)
  end
end
