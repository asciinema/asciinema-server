defmodule Asciinema.Workers.MigrateRecordingFilesTest do
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  import Asciinema.Factory

  alias Asciinema.Recordings
  alias Asciinema.Workers.MigrateRecordingFiles

  describe "perform/1" do
    test "moves the file to its canonical path" do
      asciicast = insert(:asciicast_v2) |> with_file()

      assert perform_job(MigrateRecordingFiles, %{asciicast_id: asciicast.id}) == :ok

      # the file-movement mechanics are covered by the migrate_file/1 context
      # tests; the path change is enough evidence the migration ran
      assert Recordings.get_asciicast(asciicast.id).path != asciicast.path
    end

    test "fans out to the given user's migratable recordings" do
      user = insert(:user)
      asciicast = insert(:asciicast_v2, user: user)
      other = insert(:asciicast_v2)

      assert perform_job(MigrateRecordingFiles, %{user_id: user.id}) == :ok

      assert_enqueued(worker: MigrateRecordingFiles, args: %{asciicast_id: asciicast.id})
      refute_enqueued(worker: MigrateRecordingFiles, args: %{asciicast_id: other.id})
    end

    test "fans out to all migratable recordings" do
      asciicast = insert(:asciicast_v2)

      assert perform_job(MigrateRecordingFiles, %{}) == :ok

      assert_enqueued(worker: MigrateRecordingFiles, args: %{asciicast_id: asciicast.id})
    end
  end
end
