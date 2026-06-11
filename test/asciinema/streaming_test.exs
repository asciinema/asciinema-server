defmodule Asciinema.StreamingTest do
  use Asciinema.DataCase
  import Asciinema.Factory
  alias Asciinema.Streaming
  alias Asciinema.Streaming.{Query, Stream}

  describe "create_stream/2" do
    test "default params" do
      user =
        insert(:user,
          term_theme_prefer_original: false,
          term_bold_is_bright: false,
          term_adaptive_palette: false
        )

      assert {:ok, stream} = Streaming.create_stream(user)

      assert %Stream{
               title: nil,
               term_type: nil,
               term_version: nil,
               term_cols: nil,
               term_rows: nil,
               term_theme_prefer_original: false,
               term_bold_is_bright: false,
               term_adaptive_palette: false,
               shell: nil,
               env: nil
             } = stream

      user =
        insert(:user,
          term_theme_prefer_original: true,
          term_bold_is_bright: true,
          term_adaptive_palette: true
        )

      assert {:ok, stream} = Streaming.create_stream(user)

      assert %Stream{
               term_theme_prefer_original: true,
               term_bold_is_bright: true,
               term_adaptive_palette: true
             } = stream
    end

    test "visibility" do
      user = insert(:user, default_stream_visibility: :public)

      assert {:ok, stream} = Streaming.create_stream(user)
      assert %Stream{visibility: :public} = stream

      user = insert(:user, default_stream_visibility: :private)

      assert {:ok, stream} = Streaming.create_stream(user)
      assert %Stream{visibility: :private} = stream

      assert {:ok, stream} = Streaming.create_stream(user, %{visibility: "unlisted"})
      assert %Stream{visibility: :unlisted} = stream
    end

    test "valid params" do
      user = insert(:user)

      assert {:ok, stream} =
               Streaming.create_stream(user, %{
                 title: "It's alive!",
                 term_type: "xterm-256color",
                 term_version: "VTE(123)",
                 shell: "/usr/bin/fish",
                 env: %{"USER" => "foobar", "HOSTNAME" => "ceres"}
               })

      assert %Stream{
               title: "It's alive!",
               term_type: "xterm-256color",
               term_version: "VTE(123)",
               shell: "/usr/bin/fish",
               env: %{"USER" => "foobar", "HOSTNAME" => "ceres"}
             } = stream
    end

    test "invalid params" do
      user = insert(:user)

      assert {:error, changeset} =
               Streaming.create_stream(user, %{
                 visibility: "lol",
                 term_theme_name: "lol"
               })

      assert %{visibility: _, term_theme_name: _} = errors_on(changeset)
    end

    test "live stream limit" do
      user = insert(:user, live_stream_limit: 1)

      assert {:ok, _} = Streaming.create_stream(user, %{live: true})
      assert {:ok, _} = Streaming.create_stream(user, %{live: false})

      assert {:error, {:live_stream_limit_reached, 1}} =
               Streaming.create_stream(user, %{live: true})
    end

    test "live stream limit race" do
      # This test ensures the PostgreSQL trigger prevents race conditions
      # when multiple processes try to create live streams simultaneously

      user = insert(:user, live_stream_limit: 1)

      # Start with no live streams
      insert(:stream, user: user, live: false)

      # Create multiple tasks that try to create live streams concurrently
      results =
        1..10
        |> Task.async_stream(fn _ -> Streaming.create_stream(user, %{live: true}) end)
        |> Enum.to_list()
        |> Enum.map(fn {:ok, result} -> result end)

      # Collect all results
      success_results = Enum.filter(results, &match?({:ok, _}, &1))
      error_results = Enum.filter(results, &match?({:error, _}, &1))

      # Exactly one should succeed, the rest should fail due to limit
      assert length(success_results) == 1
      assert length(error_results) == 9

      # All error results should indicate live stream limit reached
      Enum.each(error_results, fn {:error, reason} ->
        assert reason == {:live_stream_limit_reached, 1}
      end)
    end
  end

  describe "lookup_stream/2" do
    test "accepts numerical ID for public streams" do
      stream = insert(:stream, visibility: :public)
      id = stream.id

      assert %Stream{id: ^id} = Streaming.lookup_stream(to_string(id))
      assert nil == Streaming.lookup_stream("999999999999")
    end

    test "allows non-public lookup by numerical ID when enabled" do
      stream = insert(:stream, visibility: :unlisted)
      id = stream.id

      assert nil == Streaming.lookup_stream(to_string(id))
      assert %Stream{id: ^id} = Streaming.lookup_stream(to_string(id), true)
    end

    test "accepts public tokens" do
      stream = insert(:stream, public_token: "foobar1234567890")
      id = stream.id

      assert %Stream{id: ^id} = Streaming.lookup_stream("foobar1234567890")
      assert nil == Streaming.lookup_stream("zzzzzzzzzzzzzzzz")
    end
  end

  describe "update_stream/2" do
    test "valid params" do
      stream =
        insert(:stream,
          title: nil,
          term_type: nil,
          term_version: nil,
          shell: nil,
          env: nil
        )

      assert {:ok, stream} =
               Streaming.update_stream(stream, %{
                 title: "It's alive!",
                 term_type: "xterm-256color",
                 term_version: "VTE(123)",
                 shell: "/usr/bin/fish",
                 env: %{"USER" => "foobar", "HOSTNAME" => "ceres"}
               })

      assert %Stream{
               title: "It's alive!",
               term_type: "xterm-256color",
               term_version: "VTE(123)",
               shell: "/usr/bin/fish",
               env: %{"USER" => "foobar", "HOSTNAME" => "ceres"}
             } = stream
    end

    test "invalid params" do
      stream = insert(:stream)

      assert {:error, changeset} =
               Streaming.update_stream(stream, %{
                 visibility: "lol",
                 term_theme_name: "lol"
               })

      assert %{visibility: _, term_theme_name: _} = errors_on(changeset)
    end

    test "invalid schedule" do
      stream = insert(:stream)

      {:error, changeset} = Streaming.update_stream(stream, %{schedule: "x"})
      assert %{schedule: _} = errors_on(changeset)

      {:error, changeset} = Streaming.update_stream(stream, %{schedule: "@reboot"})
      assert %{schedule: _} = errors_on(changeset)
    end

    test "live stream limit" do
      user = insert(:user, live_stream_limit: 1)
      stream_1 = insert(:stream, user: user, live: false)
      stream_2 = insert(:stream, user: user, live: false)

      assert {:ok, _} = Streaming.update_stream(stream_1, %{live: true})

      assert {:error, {:live_stream_limit_reached, 1}} =
               Streaming.update_stream(stream_2, %{live: true})
    end

    test "live stream limit race" do
      # This test ensures the PostgreSQL trigger prevents race conditions
      # when multiple processes try to update streams to live simultaneously

      user = insert(:user, live_stream_limit: 1)

      # Start with no live streams
      streams = insert_list(10, :stream, user: user, live: false)

      # Create multiple tasks that try to make streams live concurrently
      results =
        streams
        |> Task.async_stream(fn stream -> Streaming.update_stream(stream, %{live: true}) end)
        |> Enum.to_list()
        |> Enum.map(fn {:ok, result} -> result end)

      # Collect all results
      success_results = Enum.filter(results, &match?({:ok, _}, &1))
      error_results = Enum.filter(results, &match?({:error, _}, &1))

      # Exactly one should succeed, the rest should fail due to limit
      assert length(success_results) == 1
      assert length(error_results) == 9

      # All error results should indicate live stream limit reached
      Enum.each(error_results, fn {:error, reason} ->
        assert reason == {:live_stream_limit_reached, 1}
      end)
    end

    test "auto-update of next_start_at" do
      user = insert(:user, timezone: "Europe/Warsaw")
      stream = insert(:stream, user: user, schedule: nil, next_start_at: nil)

      {:ok, stream} = Streaming.update_stream(stream, %{schedule: "0 20 1 6 * 2050"})
      assert stream.next_start_at == ~U[2050-06-01T18:00:00Z]

      {:ok, stream} = Streaming.update_stream(stream, %{schedule: ""})
      assert stream.next_start_at == nil

      {:ok, stream} = Streaming.update_stream(stream, %{schedule: "0 21 1 12 * 2000"})
      assert stream.next_start_at == nil

      {:error, changeset} = Streaming.update_stream(stream, %{schedule: "@reboot"})
      assert %{schedule: _} = errors_on(changeset)
    end
  end

  describe "mark_inactive_streams_offline/0" do
    test "marks inactive/disconnected streams beyond their grace period as offline" do
      # Stream active within last minute - should stay live
      recent_stream =
        insert(:stream,
          live: true,
          last_activity_at: Timex.shift(Timex.now(), seconds: -30),
          offline_grace_period: 60
        )

      # Stream inactive for more than 2 minutes - should be marked offline
      old_stream =
        insert(:stream,
          live: true,
          last_activity_at: Timex.shift(Timex.now(), seconds: -128),
          offline_grace_period: 120
        )

      # Stream with nil last_activity_at but recent inserted_at - should stay live
      new_stream =
        insert(:stream,
          live: true,
          last_activity_at: nil,
          inserted_at: Timex.shift(Timex.now(), seconds: -30),
          offline_grace_period: 60
        )

      # Stream with nil last_activity_at and old inserted_at - should be marked offline
      old_new_stream =
        insert(:stream,
          live: true,
          last_activity_at: nil,
          inserted_at: Timex.shift(Timex.now(), minutes: -2),
          offline_grace_period: 60
        )

      # Already offline stream - should remain unchanged
      insert(:stream,
        live: false,
        last_activity_at: Timex.shift(Timex.now(), minutes: -10),
        offline_grace_period: 300
      )

      count = Streaming.mark_inactive_streams_offline()

      assert count == 2

      recent_stream = reload(recent_stream)
      old_stream = reload(old_stream)
      new_stream = reload(new_stream)
      old_new_stream = reload(old_new_stream)

      assert recent_stream.live == true
      assert old_stream.live == false
      assert old_stream.current_viewer_count == 0
      assert new_stream.live == true
      assert old_new_stream.live == false
      assert old_new_stream.current_viewer_count == 0
    end
  end

  describe "query/1" do
    test "requires an explicit query scope" do
      assert_raise ArgumentError, fn ->
        struct!(Query, filters: [])
      end
    end

    test "applies public and listing scopes" do
      owner = insert(:user)
      viewer = insert(:user)

      public = insert(:stream, user: owner, visibility: :public)
      unlisted = insert(:stream, user: owner, visibility: :unlisted)
      private = insert(:stream, user: owner, visibility: :private)

      public_ids =
        %Query{scope: :public_listing}
        |> Streaming.list(10)
        |> Enum.map(& &1.id)

      viewer_ids =
        %Query{scope: {:listing_for, viewer}}
        |> Streaming.list(10)
        |> Enum.map(& &1.id)

      anonymous_ids =
        %Query{scope: {:listing_for, nil}}
        |> Streaming.list(10)
        |> Enum.map(& &1.id)

      owner_ids =
        %Query{scope: {:listing_for, owner}}
        |> Streaming.list(10)
        |> Enum.map(& &1.id)

      assert public.id in public_ids
      refute unlisted.id in public_ids
      refute private.id in public_ids

      assert Enum.sort(public_ids) == Enum.sort(viewer_ids)
      assert Enum.sort(public_ids) == Enum.sort(anonymous_ids)
      assert public.id in owner_ids
      assert unlisted.id in owner_ids
      assert private.id in owner_ids
    end

    test "filters by user, id exclusion, live, prefix, title search, and reschedulable" do
      user = insert(:user)
      other_user = insert(:user)
      now = DateTime.utc_now()

      target =
        insert(:stream,
          user: user,
          title: "Deploy Demo",
          public_token: "deploymatch12345",
          live: true,
          next_start_at: DateTime.add(now, -60)
        )

      excluded =
        insert(:stream,
          user: user,
          title: "Deploy Demo",
          public_token: "deploymatch54321",
          live: true,
          next_start_at: DateTime.add(now, -60)
        )

      insert(:stream,
        user: other_user,
        title: "Deploy Demo",
        public_token: "deploymatch99999",
        live: true,
        next_start_at: DateTime.add(now, -60)
      )

      insert(:stream,
        user: user,
        title: "Other Demo",
        public_token: "deploymatch88888",
        live: true,
        next_start_at: DateTime.add(now, -60)
      )

      insert(:stream,
        user: user,
        title: "Deploy Other",
        public_token: "deploymatch11111",
        live: true,
        next_start_at: DateTime.add(now, -60)
      )

      insert(:stream,
        user: user,
        title: "Deploy Demo",
        public_token: "othermatch12345",
        live: true,
        next_start_at: DateTime.add(now, -60)
      )

      insert(:stream,
        user: user,
        title: "Deploy Demo",
        public_token: "deploymatch77777",
        live: false,
        next_start_at: DateTime.add(now, -60)
      )

      insert(:stream,
        user: user,
        title: "Deploy Demo",
        public_token: "deploymatch66666",
        live: true,
        next_start_at: DateTime.add(now, 60)
      )

      results =
        %Query{
          scope: :system,
          filters: [
            {:user, user},
            {:id, {:not_eq, excluded.id}},
            :live,
            {:prefix, "deploy"},
            {:title, {:search, "deploy demo"}},
            :reschedulable
          ]
        }
        |> Streaming.list(10)

      assert Enum.map(results, & &1.id) == [target.id]
    end

    test "filters by recording count" do
      with_recordings = insert(:stream)
      insert_list(2, :asciicast, stream_id: with_recordings.id)
      without_recordings = insert(:stream)

      assert %Query{scope: :system, filters: [{:recording_count, {:gt, 0}}]}
             |> Streaming.list(10)
             |> Enum.map(& &1.id) == [with_recordings.id]

      assert %Query{scope: :system, filters: [{:recording_count, {:eq, 0}}]}
             |> Streaming.list(10)
             |> Enum.map(& &1.id) == [without_recordings.id]

      assert %Query{scope: :system, filters: [{:recording_count, {:between, 1, 3}}]}
             |> Streaming.list(10)
             |> Enum.map(& &1.id) == [with_recordings.id]
    end

    test "filters by token (exact public_token match)" do
      target = insert(:stream, public_token: "tok-target-aaaaaaaa")
      insert(:stream, public_token: "tok-other-bbbbbbbbbb")

      assert %Query{scope: :system, filters: [{:token, "tok-target-aaaaaaaa"}]}
             |> Streaming.list(10)
             |> Enum.map(& &1.id) == [target.id]
    end

    test "nil prefix is ignored" do
      stream = insert(:stream)

      results =
        %Query{scope: :system, filters: [{:prefix, nil}]}
        |> Streaming.list(10)

      assert stream.id in Enum.map(results, & &1.id)
    end

    test "title search treats LIKE wildcards literally" do
      # "a_c" must match the literal underscore, not "_" as a single-char wildcard
      literal = insert(:stream, title: "a_c")
      decoy = insert(:stream, title: "axc")

      results =
        %Query{scope: :system, filters: [{:title, {:search, "a_c"}}]}
        |> Streaming.list(10)

      ids = Enum.map(results, & &1.id)
      assert literal.id in ids
      refute decoy.id in ids
    end

    test "filters by id, public status, live false, schedule, and audio presence" do
      user = insert(:user)

      scheduled =
        insert(:stream,
          user: user,
          visibility: :public,
          live: false,
          audio_url: "https://example.com/audio"
        )

      {:ok, scheduled} =
        Streaming.update_stream(scheduled, %{schedule: "0 20 1 6 * 2050"})

      private = insert(:stream, user: user, visibility: :private, live: true)
      public_live = insert(:stream, user: user, visibility: :public, live: true)

      assert_ids = fn filter, expected ->
        ids =
          %Query{scope: :system, filters: [{:user, user.id}, filter]}
          |> Streaming.list(10)
          |> Enum.map(& &1.id)
          |> Enum.sort()

        assert ids == Enum.sort(expected)
      end

      assert_ids.({:id, private.id}, [private.id])
      assert_ids.(:public, [scheduled.id, public_live.id])
      assert_ids.({:live, false}, [scheduled.id])
      assert_ids.({:scheduled, true}, [scheduled.id])
      assert_ids.({:scheduled, false}, [private.id, public_live.id])
      assert_ids.({:audio, true}, [scheduled.id])
      assert_ids.({:audio, false}, [private.id, public_live.id])
    end

    test "filters by created time, start time, and viewer counts" do
      user = insert(:user)

      never =
        insert(:stream,
          user: user,
          inserted_at: ~U[2025-01-01 00:00:00Z],
          last_started_at: nil,
          current_viewer_count: 0,
          peak_viewer_count: 0
        )

      recent =
        insert(:stream,
          user: user,
          inserted_at: ~U[2025-02-01 00:00:00Z],
          last_started_at: ~U[2025-02-02 00:00:00Z],
          current_viewer_count: 10,
          peak_viewer_count: 20
        )

      assert_id = fn filter, expected ->
        assert [%{id: id}] =
                 %Query{scope: :system, filters: [{:user, user.id}, filter]}
                 |> Streaming.list(10)

        assert id == expected.id
      end

      assert_id.({:created_at, {:gte, ~U[2025-01-15 00:00:00Z]}}, recent)
      assert_id.({:last_started_at, :never}, never)
      assert_id.({:last_started_at, {:gte, ~U[2025-02-01 00:00:00Z]}}, recent)
      assert_id.({:current_viewer_count, {:between, 5, 15}}, recent)
      assert_id.({:peak_viewer_count, {:gt, 10}}, recent)
    end

    test "filters upcoming streams and sorts by soonest start" do
      soon =
        insert(:stream, live: false, next_start_at: DateTime.shift(DateTime.utc_now(), minute: 5))

      later =
        insert(:stream,
          live: false,
          next_start_at: DateTime.shift(DateTime.utc_now(), minute: 10)
        )

      insert(:stream, live: true, next_start_at: DateTime.shift(DateTime.utc_now(), minute: 1))
      insert(:stream, live: false, next_start_at: nil)

      results =
        %Query{scope: :system, filters: [:upcoming], sort: :soonest}
        |> Streaming.list(10)

      assert Enum.map(results, & &1.id) == [soon.id, later.id]
    end

    test "sorts by activity and recently started" do
      older_live = insert(:stream, live: true, last_started_at: ~U[2026-01-01 00:00:00Z])
      newer_live = insert(:stream, live: true, last_started_at: ~U[2026-01-02 00:00:00Z])
      offline = insert(:stream, live: false, last_started_at: ~U[2026-01-03 00:00:00Z])

      activity_results =
        %Query{scope: :system, sort: :activity}
        |> Streaming.list(10)

      recent_results =
        %Query{scope: :system, sort: :recently_started}
        |> Streaming.list(10)

      assert Enum.map(activity_results, & &1.id) == [newer_live.id, older_live.id, offline.id]
      assert Enum.map(recent_results, & &1.id) == [offline.id, newer_live.id, older_live.id]
    end
  end

  describe "paginate/4" do
    test "caps total entries and pages when max_pages is set" do
      user = insert(:user)
      insert_list(21, :stream, user: user)

      page =
        %Query{scope: :system, filters: [{:user, user}], sort: :id}
        |> Streaming.paginate(11, 2, max_pages: 10)

      assert page.total_pages == 10
      assert page.total_entries == 20
      assert page.page_number == 10
      assert length(page.entries) == 2
    end

    test "doesn't cap pages when max_pages is not set" do
      user = insert(:user)
      insert_list(21, :stream, user: user)

      page =
        %Query{scope: :system, filters: [{:user, user}], sort: :id}
        |> Streaming.paginate(11, 2)

      assert page.total_pages > 10
      assert page.page_number == 11
      assert page.total_entries == 21
    end
  end

  defp reload(stream), do: Streaming.get_stream(stream.id)

  describe "admin query execution" do
    test "returns all streams including private and offline" do
      insert(:stream, visibility: :private, live: false)
      insert(:stream, visibility: :public, live: true)

      assert length(Streaming.list(%Query{scope: :admin}, 1000)) == 2
    end

    test "filters by visibility" do
      insert(:stream, visibility: :private)
      insert(:stream, visibility: :public)

      results =
        %Query{scope: :admin, filters: [{:visibility, :private}]}
        |> Streaming.list(1000)

      assert length(results) == 1
    end

    test "filters by live" do
      insert(:stream, live: true)
      insert(:stream, live: false)

      results =
        %Query{scope: :admin, filters: [{:live, true}]}
        |> Streaming.list(1000)

      assert length(results) == 1
    end

    test "filters by user" do
      u = insert(:user)
      insert_list(2, :stream, user: u)
      insert(:stream)

      results =
        %Query{scope: :admin, filters: [{:user, u.id}]}
        |> Streaming.list(1000)

      assert length(results) == 2
    end

    test "search by title" do
      target = insert(:stream, title: "My Live Demo")
      insert(:stream, title: "Other")

      assert [%{id: id}] =
               %Query{scope: :admin, filters: [{:title, {:search, "demo"}}]}
               |> Streaming.list(10)

      assert id == target.id
    end

    test "filters by username" do
      u = insert(:user, username: "alicia")
      target = insert(:stream, user: u)
      insert(:stream)

      assert [%{id: id}] =
               %Query{scope: :admin, filters: [{:user, "alicia"}]}
               |> Streaming.list(10)

      assert id == target.id
    end

    test "respects limit" do
      insert_list(5, :stream)
      assert length(Streaming.list(%Query{scope: :admin}, 2)) == 2
    end

    test "sorts nullable viewer counts after known counts" do
      user = insert(:user)
      unknown = insert(:stream, user: user, current_viewer_count: nil)
      low = insert(:stream, user: user, current_viewer_count: 1)
      high = insert(:stream, user: user, current_viewer_count: 2)

      ids =
        %Query{
          scope: :admin,
          filters: [{:user, user.id}],
          sort: {:current_viewers, :desc}
        }
        |> Streaming.list(3)
        |> Enum.map(& &1.id)

      assert ids == [high.id, low.id, unknown.id]
    end

    test "paginates in display order" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      first = insert(:stream, last_started_at: DateTime.add(now, -300))
      second = insert(:stream, last_started_at: DateTime.add(now, -200))
      third = insert(:stream, last_started_at: DateTime.add(now, -100))

      page =
        %Query{scope: :admin, sort: {:last_started, :desc}}
        |> Streaming.paginate(1, 2)

      ids = Enum.map(page.entries, & &1.id)
      assert ids == [third.id, second.id]
      refute first.id in ids
    end
  end

  describe "disconnect_stream/1" do
    test "returns {:error, :not_running} when the GenServer isn't started" do
      stream = insert(:stream)

      assert {:error, :not_running} = Streaming.disconnect_stream(stream)
    end
  end
end
