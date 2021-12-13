defmodule Asciinema.Repo.Migrations.AddColsRowsOverrides do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :cols_override, :integer
      add :rows_override, :integer
    end
  end
end
