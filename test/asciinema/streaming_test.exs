defmodule Asciinema.StreamingTest do
  use Asciinema.DataCase
  import Asciinema.Factory
  alias Asciinema.Streaming
  alias Asciinema.Streaming.Stream

  describe "create_stream/2" do
    test "default params" do
      user = insert(:user)

      assert {:ok, stream} = Streaming.create_stream(user)

      assert %Stream{
               title: nil,
               term_type: nil,
               term_version: nil,
               term_cols: nil,
               term_rows: nil,
               shell: nil,
               env: nil
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

    test "live stream limit" do
      user = insert(:user, live_stream_limit: 1)
      stream_1 = insert(:stream, user: user, live: false)
      stream_2 = insert(:stream, user: user, live: false)

      assert {:ok, _} = Streaming.update_stream(stream_1, %{live: true})

      assert {:error, {:live_stream_limit_reached, 1}} =
               Streaming.update_stream(stream_2, %{live: true})
    end
  end

  describe "mark_inactive_streams_offline/0" do
    test "marks live streams inactive for more than 1 minute as offline" do
      # Stream active within last minute - should stay live
      recent_stream =
        insert(:stream, live: true, last_activity_at: Timex.shift(Timex.now(), seconds: -30))

      # Stream inactive for more than 1 minute - should be marked offline
      old_stream =
        insert(:stream, live: true, last_activity_at: Timex.shift(Timex.now(), minutes: -2))

      # Stream with nil last_activity_at but recent inserted_at - should stay live
      new_stream =
        insert(:stream,
          live: true,
          last_activity_at: nil,
          inserted_at: Timex.shift(Timex.now(), seconds: -30)
        )

      # Stream with nil last_activity_at and old inserted_at - should be marked offline
      old_new_stream =
        insert(:stream,
          live: true,
          last_activity_at: nil,
          inserted_at: Timex.shift(Timex.now(), minutes: -2)
        )

      # Already offline stream - should remain unchanged
      insert(:stream, live: false, last_activity_at: Timex.shift(Timex.now(), minutes: -2))

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

  defp reload(stream), do: Streaming.get_stream(stream.id)
end
