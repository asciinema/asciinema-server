defmodule Asciinema.Workers.GenerateSnapshotsTest do
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  import Asciinema.Factory

  alias Asciinema.Workers.{GenerateSnapshots, UpdateSnapshot}

  describe "perform/1" do
    test "enqueues snapshot generation for snapshotless recordings only" do
      snapshotless = insert(:asciicast, snapshot: nil)
      snapshotted = insert(:asciicast, snapshot: {[[["foo", %{}, 1]]], nil})

      assert perform_job(GenerateSnapshots, %{}) == :ok

      assert_enqueued(worker: UpdateSnapshot, args: %{asciicast_id: snapshotless.id})
      refute_enqueued(worker: UpdateSnapshot, args: %{asciicast_id: snapshotted.id})
    end
  end
end
