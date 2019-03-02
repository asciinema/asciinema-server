defmodule Asciinema.Repo.Migrations.AddArchivableToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :archivable, :boolean, null: false, default: true
    end
  end
end
