defmodule Asciinema.Repo.Migrations.AddCursorModeToMedia do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :term_cursor_mode, :string, default: "blinking", null: false
    end

    alter table(:streams) do
      add :term_cursor_mode, :string, default: "blinking", null: false
    end
  end
end
