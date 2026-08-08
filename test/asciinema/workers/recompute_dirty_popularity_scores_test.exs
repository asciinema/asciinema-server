defmodule Asciinema.Workers.RecomputeDirtyPopularityScoresTest do
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  import Asciinema.Factory

  alias Asciinema.Recordings.AsciicastStats
  alias Asciinema.Workers.RecomputeDirtyPopularityScores

  describe "perform/1" do
    test "recomputes scores for dirty recordings" do
      asciicast = insert(:asciicast)
      insert(:asciicast_stats, asciicast_id: asciicast.id, popularity_dirty: true)

      assert perform_job(RecomputeDirtyPopularityScores, %{}) == :ok

      refute Repo.get_by!(AsciicastStats, asciicast_id: asciicast.id).popularity_dirty
    end
  end
end
