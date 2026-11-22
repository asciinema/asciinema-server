defmodule AsciinemaWeb.StreamCardLiveTest do
  use ExUnit.Case, async: true

  import Asciinema.Factory
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias AsciinemaWeb.StreamCardLive
  alias Asciinema.Recordings.Snapshot
  import Asciinema.PngUtil

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

    test "renders the captured stream palette and snapshot with terminal styling" do
      palette =
        Enum.map_join(0..15, ":", fn i -> if i == 9, do: "#abcdef", else: "#123456" end)

      stream =
        build(:stream,
          term_theme_name: "asciinema",
          term_theme_prefer_original: true,
          term_theme_fg: "#ffffff",
          term_theme_bg: "#000000",
          term_theme_palette: palette,
          term_bold_is_bright: true,
          term_adaptive_palette: true,
          snapshot:
            Snapshot.from_segments([
              [{"█", %{"fg" => 1, "bold" => true}, 1}, {"█", %{"fg" => 21}, 1}]
            ])
        )

      html =
        rendered_to_string(
          StreamCardLive.render(%{stream: stream, status: :live, show_visibility_badge: false})
        )

      [_, encoded] = Regex.run(~r/href="data:image\/png;base64,([^"]+)"/, html)
      png = decode_png(Base.decode64!(encoded))
      assert {png.width, png.height} == {576, 384}
      assert cell_contains_color?(png, 0, 0, {171, 205, 239})
      assert cell_contains_color?(png, 1, 0, {18, 52, 86})
      refute html =~ "<?xml"
      refute html =~ "small-triangle-mask"
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
