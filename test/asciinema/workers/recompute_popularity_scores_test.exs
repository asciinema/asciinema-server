defmodule Asciinema.Workers.RecomputePopularityScoresTest do
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  import Asciinema.Factory

  alias Asciinema.Recordings.AsciicastStats
  alias Asciinema.Workers.RecomputePopularityScores

  describe "perform/1" do
    test "zeroes stale scores of recordings without recent views" do
      asciicast = insert(:asciicast)
      insert(:asciicast_stats, asciicast_id: asciicast.id, popularity_score: 5.0)

      assert perform_job(RecomputePopularityScores, %{}) == :ok

      assert Repo.get_by!(AsciicastStats, asciicast_id: asciicast.id).popularity_score == 0.0
    end
  end
end
