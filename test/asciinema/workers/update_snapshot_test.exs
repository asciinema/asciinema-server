defmodule Asciinema.Workers.UpdateSnapshotTest do
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  import Asciinema.Factory

  alias Asciinema.Recordings
  alias Asciinema.Workers.UpdateSnapshot

  describe "perform/1" do
    test "generates the snapshot" do
      asciicast = insert(:asciicast_v2, snapshot: nil) |> with_file()

      assert perform_job(UpdateSnapshot, %{asciicast_id: asciicast.id}) == :ok

      assert Recordings.get_asciicast(asciicast.id, load_snapshot: true).snapshot != nil
    end

    test "discards the job when the recording is gone" do
      assert perform_job(UpdateSnapshot, %{asciicast_id: -1}) == :discard
    end
  end
end
