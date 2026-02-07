defmodule Asciinema.Repo.Migrations.CreateAsciicastFts do
  use Ecto.Migration

  def up do
    create table(:asciicast_fts, primary_key: false) do
      add :asciicast_id, references(:asciicasts, on_delete: :delete_all),
        primary_key: true,
        null: false

      add :title_tsv, :tsvector, null: false
      add :description_tsv, :tsvector, null: false
      add :content_tsv, :tsvector
    end

    execute """
    INSERT INTO asciicast_fts (asciicast_id, title_tsv, description_tsv, content_tsv)
    SELECT id, title_tsv, description_tsv, content_tsv
    FROM asciicasts;
    """

    execute """
    CREATE INDEX asciicast_fts_index
    ON asciicast_fts
    USING GIN ((title_tsv || description_tsv || coalesce(content_tsv, ''::tsvector)));
    """

    execute """
    CREATE OR REPLACE FUNCTION upsert_asciicast_fts()
    RETURNS trigger
    LANGUAGE plpgsql AS
    $$
    BEGIN
      INSERT INTO asciicast_fts (asciicast_id, title_tsv, description_tsv)
      VALUES (
        NEW.id,
        to_tsvector('simple', coalesce(NEW.title, '')),
        to_tsvector('simple', coalesce(NEW.description, ''))
      )
      ON CONFLICT (asciicast_id) DO UPDATE
        SET title_tsv = EXCLUDED.title_tsv,
            description_tsv = EXCLUDED.description_tsv;

      RETURN NEW;
    END;
    $$;
    """

    execute """
    CREATE TRIGGER trg_asciicast_fts_upsert
    AFTER INSERT OR UPDATE OF title, description ON asciicasts
    FOR EACH ROW
    EXECUTE FUNCTION upsert_asciicast_fts();
    """
  end

  def down do
    execute """
    DROP TRIGGER IF EXISTS trg_asciicast_fts_upsert ON asciicasts;
    """

    execute """
    DROP FUNCTION IF EXISTS upsert_asciicast_fts();
    """

    execute "DROP INDEX asciicast_fts_index"
    drop table(:asciicast_fts)
  end
end
