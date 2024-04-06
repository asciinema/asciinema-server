defmodule Asciinema.Repo.Migrations.AddThemePreferOriginalToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :theme_prefer_original, :boolean, null: false, default: true
    end

    execute "UPDATE asciicasts SET theme_name='original' WHERE theme_name IS NULL AND theme_palette IS NOT NULL"
  end
end
