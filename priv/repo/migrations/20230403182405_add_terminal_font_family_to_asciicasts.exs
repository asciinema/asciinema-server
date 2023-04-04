defmodule Asciinema.Repo.Migrations.AddTerminalFontFamilyToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :terminal_font_family, :string
    end
  end
end
