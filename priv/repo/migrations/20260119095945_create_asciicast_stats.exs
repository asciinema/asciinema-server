defmodule Asciinema.Repo.Migrations.CreateAsciicastStats do
  use Ecto.Migration

  def up do
    create table(:asciicast_stats, primary_key: false) do
      add :asciicast_id, references(:asciicasts, on_delete: :delete_all),
        primary_key: true,
        null: false

      add :total_views, :integer, null: false, default: 0
      add :popularity_score, :float, null: false, default: 0.0
      add :popularity_dirty, :boolean, null: false
    end

    create index(:asciicasts, ["id DESC"],
      where: "visibility = 'public' AND archived_at IS NULL",
      name: "asciicasts_public_non_archived_index"
    )

    create index(:asciicast_stats, ["popularity_score DESC", "asciicast_id DESC"],
      where: "popularity_score > 0.0",
      name: "asciicast_stats_popular_index"
    )

    create index(:asciicast_stats, [:asciicast_id], where: "popularity_dirty = true")

    execute """
    INSERT INTO asciicast_stats (asciicast_id, popularity_score, total_views, popularity_dirty)
    SELECT id, popularity_score, views_count, popularity_dirty
    FROM asciicasts;
    """

    alter table(:asciicasts) do
      remove :popularity_score
      remove :popularity_dirty
      remove :views_count
    end
  end

  def down do
    alter table(:asciicasts) do
      add :popularity_score, :float, null: false, default: 0.0
      add :popularity_dirty, :boolean, null: false, default: false
      add :views_count, :integer, null: false, default: 0
    end

    execute """
    UPDATE asciicasts
    SET popularity_score = s.popularity_score,
        popularity_dirty = s.popularity_dirty,
        views_count = s.total_views
    FROM asciicast_stats s
    WHERE asciicasts.id = s.asciicast_id;
    """

    create index(:asciicasts, ["popularity_score DESC", "id DESC"],
      where: "visibility = 'public' AND popularity_score > 0.0 AND archived_at IS NULL"
    )

    create index(:asciicasts, [:id], where: "popularity_dirty = true AND archived_at IS NULL")

    create index(:asciicasts, [:views_count], name: "index_asciicasts_on_views_count")

    drop index(:asciicasts, ["id DESC"], name: "asciicasts_public_non_archived_index")

    drop table(:asciicast_stats)
  end
end
