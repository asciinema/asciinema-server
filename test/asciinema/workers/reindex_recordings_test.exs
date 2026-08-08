defmodule Asciinema.Workers.ReindexRecordingsTest do
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  import Asciinema.Factory

  alias Asciinema.Workers.{ReindexRecordings, UpdateFtsContent}

  describe "perform/1" do
    test "enqueues FTS content update for every recording" do
      [asciicast_1, asciicast_2] = insert_list(2, :asciicast)

      assert perform_job(ReindexRecordings, %{}) == :ok

      assert_enqueued(worker: UpdateFtsContent, args: %{asciicast_id: asciicast_1.id})
      assert_enqueued(worker: UpdateFtsContent, args: %{asciicast_id: asciicast_2.id})
    end
  end
end
