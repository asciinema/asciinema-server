defmodule Asciinema.Workers.DeleteUnclaimedRecordingsTest do
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  import Asciinema.Factory

  alias Asciinema.{AppEnv, Recordings}
  alias Asciinema.Workers.DeleteUnclaimedRecordings

  describe "perform/1" do
    test "hides and deletes unclaimed recordings per configured TTLs" do
      AppEnv.put(:unclaimed_recording_ttl, hide: 7, delete: 30)

      tmp_user = insert(:temporary_user, email: nil)
      fresh = insert(:asciicast, user: tmp_user, inserted_at: days_ago(2))
      stale = insert(:asciicast, user: tmp_user, inserted_at: days_ago(8))
      ancient = insert(:asciicast, user: tmp_user, inserted_at: days_ago(31))
      claimed = insert(:asciicast, inserted_at: days_ago(31))

      assert perform_job(DeleteUnclaimedRecordings, %{}) == :ok

      assert Recordings.get_asciicast(fresh.id).archived_at == nil
      assert Recordings.get_asciicast(stale.id).archived_at != nil
      assert Recordings.get_asciicast(ancient.id) == nil
      assert Recordings.get_asciicast(claimed.id).archived_at == nil
    end

    test "is a no-op when no TTLs are configured" do
      tmp_user = insert(:temporary_user, email: nil)
      ancient = insert(:asciicast, user: tmp_user, inserted_at: days_ago(1000))

      assert perform_job(DeleteUnclaimedRecordings, %{}) == :ok

      assert Recordings.get_asciicast(ancient.id).archived_at == nil
    end
  end

  defp days_ago(days), do: DateTime.add(DateTime.utc_now(), -days * 86_400)
end
