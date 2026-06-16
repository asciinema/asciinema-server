defmodule Asciinema.Repo.Migrations.AddAdaptivePaletteToMedia do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :term_adaptive_palette, :boolean, default: false, null: false
    end

    alter table(:asciicasts) do
      add :term_adaptive_palette, :boolean, default: false, null: false
    end

    alter table(:streams) do
      add :term_adaptive_palette, :boolean, default: false, null: false
    end
  end
end
