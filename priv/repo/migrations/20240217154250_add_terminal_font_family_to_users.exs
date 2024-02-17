defmodule Asciinema.Repo.Migrations.AddTerminalFontFamilyToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :terminal_font_family, :string
    end
  end
end
