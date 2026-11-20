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

    test "enqueues regeneration for all recordings when requested, including archived ones" do
      snapshotless = insert(:asciicast, snapshot: nil)
      snapshotted = insert(:asciicast, snapshot: {[[["foo", %{}, 1]]], nil})

      archived =
        insert(:asciicast,
          snapshot: {[[["bar", %{}, 1]]], nil},
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        )

      assert perform_job(GenerateSnapshots, %{all: true}) == :ok

      for recording <- [snapshotless, snapshotted, archived] do
        assert_enqueued(worker: UpdateSnapshot, args: %{asciicast_id: recording.id})
      end
    end
  end
end
