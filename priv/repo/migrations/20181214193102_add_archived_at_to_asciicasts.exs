defmodule Asciinema.Repo.Migrations.AddArchivedAtToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :archived_at, :naive_datetime
    end
  end
end
