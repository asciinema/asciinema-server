defmodule Asciinema.Repo.Migrations.AddUserLiveStreamLimitCheck do
  use Ecto.Migration

  def up do
    create index(:streams, [:user_id], where: "live", name: "streams_user_live_index")

    execute """
      CREATE OR REPLACE FUNCTION enforce_live_stream_limit()
      RETURNS trigger
      LANGUAGE plpgsql AS
      $$
      DECLARE
          max_allowed integer;
          concurrent  integer;
      BEGIN
          /* --------------------------------------------------------
             Run only when the row *enters* the live state
          ---------------------------------------------------------*/
          IF TG_OP = 'INSERT' THEN
              IF NEW.live IS NOT TRUE THEN       -- plain insert of a non-live row
                  RETURN NEW;
              END IF;
          ELSIF TG_OP = 'UPDATE' THEN
              IF NEW.live IS NOT TRUE            -- turning it off, or staying off
                 OR OLD.live IS TRUE             -- was already live
              THEN
                  RETURN NEW;
              END IF;
          END IF;

          /* --------------------------------------------------------
             Fetch the limit (and lock the users row so rivals queue)
          ---------------------------------------------------------*/
          SELECT live_stream_limit
            INTO max_allowed
            FROM users
           WHERE id = NEW.user_id
           FOR UPDATE;

          /* Unlimited user?  Nothing to enforce. */
          IF max_allowed IS NULL THEN
              RETURN NEW;
          END IF;

          /* --------------------------------------------------------
             How many *other* live streams does this user have?
             (The current row isn’t live in the table yet.)
          ---------------------------------------------------------*/
          SELECT COUNT(*)
            INTO concurrent
            FROM streams
           WHERE user_id = NEW.user_id
             AND live;

          IF concurrent >= max_allowed THEN
              RAISE EXCEPTION 'live_stream_limit_exceeded'
                USING ERRCODE   = '23514',       -- check_violation
                      CONSTRAINT = 'live_stream_limit';
          END IF;

          RETURN NEW;
      END;
      $$;
    """

    execute """
      DROP TRIGGER IF EXISTS trg_enforce_live_stream_limit ON streams;
    """

    execute """
      CREATE TRIGGER trg_enforce_live_stream_limit
      BEFORE INSERT OR UPDATE OF live ON streams
      FOR EACH ROW
      EXECUTE FUNCTION enforce_live_stream_limit();
    """
  end

  def down do
    execute """
      DROP TRIGGER IF EXISTS trg_enforce_live_stream_limit ON streams;
    """

    execute """
      DROP FUNCTION IF EXISTS enforce_live_stream_limit();
    """

    drop index(:streams, [:user_id], name: "streams_user_live_index")
  end
end
