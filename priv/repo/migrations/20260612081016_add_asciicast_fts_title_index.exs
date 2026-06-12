defmodule Asciinema.Repo.Migrations.AddAsciicastFtsTitleIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  # The existing GIN covers only the title/description/content concatenation;
  # title-only searches need their own.
  def change do
    create index(:asciicast_fts, [:title_tsv],
             name: "asciicast_fts_title_index",
             using: "GIN",
             concurrently: true
           )
  end
end
