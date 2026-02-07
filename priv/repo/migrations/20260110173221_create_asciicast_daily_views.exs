defmodule Asciinema.Repo.Migrations.CreateAsciicastDailyViews do
  use Ecto.Migration

  def up do
    create table(:asciicast_daily_views, primary_key: false) do
      add :asciicast_id, references(:asciicasts, on_delete: :delete_all), null: false
      add :date, :date, null: false
      add :count, :integer, null: false, default: 0
    end

    create unique_index(:asciicast_daily_views, [:asciicast_id, :date])
    create index(:asciicast_daily_views, [:date, :asciicast_id])

    execute """
    WITH days AS (
      -- Generate offsets for the last 7 days (0 = today).
      SELECT generate_series(0, 6) AS day_offset
    ),
    dist AS (
      -- Distribute total views into 7 buckets with a 7..1 weighting.
      SELECT a.id AS asciicast_id,
             a.views_count AS views_count,
             d.day_offset AS day_offset,
             (CURRENT_DATE - d.day_offset) AS view_date,
             (a.views_count * (7 - d.day_offset) / 28) AS base_count
      FROM asciicasts a
      CROSS JOIN days d
      WHERE a.views_count >= 10
    ),
    summed AS (
      -- Sum bucketed views to compute the remainder for today.
      SELECT dist.*,
             sum(base_count) OVER (PARTITION BY asciicast_id) AS base_sum
      FROM dist
    )
    INSERT INTO asciicast_daily_views (asciicast_id, date, count)
    SELECT asciicast_id,
           view_date,
           CASE
             -- Put the integer division remainder on today to match totals.
             WHEN day_offset = 0 THEN base_count + (views_count - base_sum)
             ELSE base_count
           END AS count
    FROM summed
    -- Skip zero buckets unless today gets a remainder.
    WHERE base_count > 0 OR (day_offset = 0 AND views_count - base_sum > 0);
    """
  end

  def down do
    drop table(:asciicast_daily_views)
  end
end
