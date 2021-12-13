defmodule Asciinema.Repo.Migrations.RenameTerminalColumnsLinesToColsRows do
  use Ecto.Migration

  def change do
    rename table(:asciicasts), :terminal_columns, to: :cols
    rename table(:asciicasts), :terminal_lines, to: :rows
  end
end
