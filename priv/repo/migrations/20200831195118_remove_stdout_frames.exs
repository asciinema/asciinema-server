defmodule Asciinema.Repo.Migrations.RemoveStdoutFrames do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      remove :stdout_frames
    end
  end
end
