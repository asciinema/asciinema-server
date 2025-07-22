defmodule Asciinema.Repo.Migrations.RenameOnlineToLiveOnStreams do
  use Ecto.Migration

  def change do
    rename table(:streams), :online, to: :live
  end
end
