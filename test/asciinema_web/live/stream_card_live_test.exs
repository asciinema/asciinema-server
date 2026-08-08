defmodule AsciinemaWeb.StreamCardLiveTest do
  use ExUnit.Case, async: true

  import Asciinema.Factory
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias AsciinemaWeb.StreamCardLive

  describe "render/1" do
    test "renders nothing when the stream no longer exists" do
      html = rendered_to_string(StreamCardLive.render(%{stream: nil}))

      assert html == ""
    end

    test "renders countdown when the stream is scheduled" do
      html = render_card({:waiting, "0d 1h 2m 3s"})

      assert html =~ "Starts in:"
      assert html =~ "0d 1h 2m 3s"
      assert html =~ "Scheduled for"
    end

    test "renders waiting label when the start time has passed" do
      html = render_card({:waiting, nil})

      assert html =~ "Waiting for the host..."
    end

    test "renders live indicator when the stream is live" do
      html = render_card(:live)

      assert html =~ "icon-live"
      refute html =~ "Starts in:"
    end

    test "renders ended label when the stream has ended" do
      html = render_card(:ended)

      assert html =~ "Stream ended"
      refute html =~ "Scheduled for"
    end
  end

  defp render_card(status) do
    stream =
      build(:stream,
        next_start_at: DateTime.add(DateTime.utc_now(), 3600, :second),
        visibility: :public
      )

    rendered_to_string(
      StreamCardLive.render(%{stream: stream, status: status, show_visibility_badge: false})
    )
  end
end
