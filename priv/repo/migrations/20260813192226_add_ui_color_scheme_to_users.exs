defmodule Asciinema.Repo.Migrations.AddUiColorSchemeToUsers do
  use Ecto.Migration

  def change do
    execute("CREATE TYPE ui_color_scheme AS ENUM ('auto', 'light', 'dark')", "DROP TYPE ui_color_scheme")

    alter table(:users) do
      add :ui_color_scheme, :ui_color_scheme, default: "auto", null: false
    end
  end
end
