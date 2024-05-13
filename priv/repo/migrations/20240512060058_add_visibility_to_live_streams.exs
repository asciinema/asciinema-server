defmodule Asciinema.Repo.Migrations.AddVisibilityToLiveStreams do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE live_stream_visibility AS ENUM ('private', 'unlisted', 'public')")

    alter table(:live_streams) do
      add :visibility, :live_stream_visibility, null: false, default: "unlisted"
    end

    execute "UPDATE live_streams SET visibility = 'public' WHERE NOT private"

    alter table(:live_streams) do
      remove :private
    end
  end

  def down do
    alter table(:live_streams) do
      add :private, :boolean, null: false, default: true
    end

    execute "UPDATE live_streams SET private = FALSE WHERE visibility = 'public'"

    alter table(:live_streams) do
      remove :visibility
    end

    execute("DROP TYPE live_stream_visibility")
  end
end
