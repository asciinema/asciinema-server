defmodule Asciinema.Repo.Migrations.AddThemeFieldsToAsciicast do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :theme_fg, :string
      add :theme_bg, :string
      add :theme_palette, :string
    end
  end
end
