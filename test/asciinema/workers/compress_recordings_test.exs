defmodule Asciinema.Workers.CompressRecordingsTest do
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  import Asciinema.Factory

  alias Asciinema.Workers.{CompressRecording, CompressRecordings}

  describe "perform/1" do
    test "enqueues uncompressed asciicasts including archived ones" do
      active = insert(:asciicast_v2, compressed: false)
      archived = insert(:asciicast_v2, compressed: false, archived_at: ~U[2024-01-01T00:00:00Z])
      compressed = insert(:asciicast_v2, compressed: true)

      assert :ok = CompressRecordings.perform(CompressRecordings.new(%{}))

      assert_enqueued(worker: CompressRecording, args: %{asciicast_id: active.id})
      assert_enqueued(worker: CompressRecording, args: %{asciicast_id: archived.id})
      refute_enqueued(worker: CompressRecording, args: %{asciicast_id: compressed.id})
    end
  end
end
