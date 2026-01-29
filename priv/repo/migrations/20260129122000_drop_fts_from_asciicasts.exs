defmodule Asciinema.Repo.Migrations.DropFtsFromAsciicasts do
  use Ecto.Migration

  def up do
    execute "DROP INDEX asciicasts_fts_index"

    execute """
    ALTER TABLE asciicasts
      DROP COLUMN title_tsv,
      DROP COLUMN description_tsv,
      DROP COLUMN content_tsv
    """
  end

  def down do
    execute """
      ALTER TABLE asciicasts
        ADD COLUMN title_tsv tsvector GENERATED ALWAYS AS (to_tsvector('simple', coalesce(title, ''))) STORED,
        ADD COLUMN description_tsv tsvector GENERATED ALWAYS AS (to_tsvector('simple', coalesce(description, ''))) STORED,
        ADD COLUMN content_tsv tsvector
    """

    execute """
    UPDATE asciicasts
    SET content_tsv = f.content_tsv
    FROM asciicast_fts f
    WHERE asciicasts.id = f.asciicast_id;
    """

    execute """
    CREATE INDEX asciicasts_fts_index
    ON asciicasts
    USING GIN ((title_tsv || description_tsv || coalesce(content_tsv, ''::tsvector)));
    """
  end
end
