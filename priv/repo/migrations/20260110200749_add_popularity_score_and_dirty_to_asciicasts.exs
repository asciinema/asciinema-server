defmodule Asciinema.Repo.Migrations.AddPopularityScoreAndDirtyToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :popularity_score, :float, null: false, default: 0.0
      add :popularity_dirty, :boolean, null: false, default: false
    end

    create index(:asciicasts, ["popularity_score DESC", "id DESC"],
      where: "visibility = 'public' AND popularity_score > 0.0 AND archived_at IS NULL"
    )

    create index(:asciicasts, [:id], where: "popularity_dirty = true AND archived_at IS NULL")

    execute(fn ->
      %{}
      |> Oban.Job.new(worker: Asciinema.Workers.RecomputePopularityScores)
      |> Asciinema.Repo.insert!()
    end, "")
  end
end
