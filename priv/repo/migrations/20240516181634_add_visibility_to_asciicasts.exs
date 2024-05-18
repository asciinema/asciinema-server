defmodule Asciinema.Repo.Migrations.AddVisibilityToAsciicasts do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE asciicast_visibility AS ENUM ('private', 'unlisted', 'public')")

    alter table(:asciicasts) do
      add :visibility, :asciicast_visibility, null: false, default: "unlisted"
    end

    execute "UPDATE asciicasts SET visibility = 'public' WHERE NOT private"

    alter table(:asciicasts) do
      remove :private
    end
  end

  def down do
    alter table(:asciicasts) do
      add :private, :boolean, null: false, default: true
    end

    execute "UPDATE asciicasts SET private = FALSE WHERE visibility = 'public'"

    alter table(:asciicasts) do
      remove :visibility
    end

    execute("DROP TYPE asciicast_visibility")
  end
end
