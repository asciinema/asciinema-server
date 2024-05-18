defmodule Asciinema.Repo.Migrations.AddDefaultAsciicastVisibilityToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :default_asciicast_visibility, :asciicast_visibility, null: false, default: "unlisted"
    end

    execute "UPDATE users SET default_asciicast_visibility = 'public' WHERE NOT asciicasts_private_by_default"

    alter table(:users) do
      remove :asciicasts_private_by_default
    end
  end

  def down do
    alter table(:users) do
      add :asciicasts_private_by_default, :boolean, null: false, default: true
    end

    execute "UPDATE users SET asciicasts_private_by_default = FALSE WHERE default_asciicast_visibility = 'public'"

    alter table(:users) do
      remove :default_asciicast_visibility
    end
  end
end
