defmodule Asciinema.Repo.Migrations.AddTerminalLineHeightToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :terminal_line_height, :float
    end
  end
end
