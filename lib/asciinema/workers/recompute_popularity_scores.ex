defmodule Asciinema.Workers.RecomputePopularityScores do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Asciinema.Recordings

  @impl Oban.Worker
  def perform(_job) do
    {:ok, _count} = Recordings.recompute_popularity_scores(:all)
    :ok
  end
end
