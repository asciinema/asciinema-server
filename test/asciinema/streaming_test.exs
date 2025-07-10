defmodule Asciinema.StreamingTest do
  use Asciinema.DataCase
  import Asciinema.Factory
  alias Asciinema.Streaming

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
