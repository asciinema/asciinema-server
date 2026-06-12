defmodule AsciinemaAdmin.DashboardTest do
  use Asciinema.DataCase, async: true
  import Asciinema.Factory
  alias AsciinemaAdmin.Dashboard

  describe "user_count/0" do
    test "counts every user" do
      base = Dashboard.user_count()
      insert_list(3, :user)
      assert Dashboard.user_count() == base + 3
    end
  end

  describe "recording_count/0" do
    test "counts every recording, archived included" do
      base = Dashboard.recording_count()
      insert_list(4, :asciicast)
      insert(:asciicast, archived_at: ~U[2020-01-01 00:00:00Z])
      assert Dashboard.recording_count() == base + 5
    end
  end

  describe "stream_count/0" do
    test "counts every stream regardless of live state" do
      base = Dashboard.stream_count()
      insert_list(2, :stream, live: true)
      insert(:stream, live: false)
      assert Dashboard.stream_count() == base + 3
    end
  end

  describe "live_stream_count/0" do
    test "counts only streams with live=true" do
      base = Dashboard.live_stream_count()
      insert_list(2, :stream, live: true)
      # the offline stream must not be counted
      insert(:stream, live: false)
      assert Dashboard.live_stream_count() == base + 2
    end
  end

  describe "recent_signups/1" do
    test "newest first" do
      first = insert(:user)
      second = insert(:user)
      third = insert(:user)

      ids = Dashboard.recent_signups(3) |> Enum.map(& &1.id)
      assert ids == [third.id, second.id, first.id]
    end

    test "respects limit" do
      insert_list(3, :user)
      assert length(Dashboard.recent_signups(2)) == 2
    end
  end

  describe "recent_recordings/1" do
    test "includes private and unlisted recordings, with user preloaded" do
      private = insert(:asciicast, visibility: :private)
      unlisted = insert(:asciicast, visibility: :unlisted)
      public = insert(:asciicast, visibility: :public)

      recordings = Dashboard.recent_recordings(10)
      ids = Enum.map(recordings, & &1.id)

      assert private.id in ids
      assert unlisted.id in ids
      assert public.id in ids
      refute match?(%Ecto.Association.NotLoaded{}, hd(recordings).user)
    end

    test "newest first, respects limit" do
      _old = insert(:asciicast)
      new = insert(:asciicast)

      assert [first | _] = Dashboard.recent_recordings(2)
      assert first.id == new.id
    end
  end

  describe "recent_stream_activity/1" do
    test "orders live streams ahead of offline ones, regardless of id" do
      live = insert(:stream, live: true)
      offline = insert(:stream, live: false)

      assert [live.id, offline.id] == Dashboard.recent_stream_activity(10) |> Enum.map(& &1.id)
    end

    test "includes offline streams, not only live ones" do
      insert(:stream, live: false)
      insert(:stream, live: true)

      assert length(Dashboard.recent_stream_activity(10)) == 2
    end

    test "includes private streams, with user preloaded" do
      insert(:stream, live: true, visibility: :private)

      assert [stream] = Dashboard.recent_stream_activity(10)
      refute match?(%Ecto.Association.NotLoaded{}, stream.user)
    end

    test "respects limit" do
      insert_list(3, :stream, live: true)
      assert length(Dashboard.recent_stream_activity(2)) == 2
    end
  end
end
