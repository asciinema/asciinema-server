defmodule AsciinemaWeb.RecordingSvgTest do
  use ExUnit.Case, async: true
  alias Asciinema.Recordings.Snapshot
  alias AsciinemaWeb.RecordingSVG
  import Asciinema.Factory

  describe "show/1" do
    test "renders SVG document" do
      asciicast =
        build(:asciicast,
          snapshot: Snapshot.new([[["foobar", %{}, 1]], [["bazqux", %{}, 1]]], :segments)
        )

      svg = render_svg(asciicast)

      assert svg =~ ~r/^<\?xml.+foobar.+bazqux/s
    end

    test "supports RGB color in fg/bg text attrs" do
      asciicast =
        build(:asciicast,
          snapshot:
            Snapshot.new(
              [
                [["foo", %{"fg" => [16, 32, 48]}, 1], ["bar", %{"bg" => "rgb(64,80,96)"}, 1]],
                [["baz", %{"fg" => "#708090"}, 1]]
              ],
              :segments
            )
        )

      svg = render_svg(asciicast)

      assert svg =~ "#102030"
      assert svg =~ "rgb(64,80,96)"
      assert svg =~ "#708090"
    end
  end

  @lines [
    [{" foo bar  baz", %{"bg" => 2}, 1}, {"!", %{"fg" => 1}, 1}],
    [{"qux", %{"bg" => "#102030"}, 1}, {"连", %{}, 2}, {"接", %{}, 2}]
  ]

  describe "fg_coords/1" do
    test "excludes whitespace" do
      coords =
        RecordingSVG.fg_coords(@lines)

      assert coords == [
               %{
                 y: 0,
                 segments: [
                   %{text: "foo bar", attrs: %{"bg" => 2}, x: 1, width: 7},
                   %{text: "baz", attrs: %{"bg" => 2}, x: 10, width: 3},
                   %{text: "!", attrs: %{"fg" => 1}, x: 13, width: 1}
                 ]
               },
               %{
                 y: 1,
                 segments: [
                   %{text: "qux", attrs: %{"bg" => "#102030"}, x: 0, width: 3},
                   %{text: "连", attrs: %{}, x: 3, width: 2},
                   %{text: "接", attrs: %{}, x: 5, width: 2}
                 ]
               }
             ]
    end
  end

  describe "bg_coords/1" do
    test "excludes segments with default background" do
      coords =
        RecordingSVG.bg_coords(@lines)

      assert coords == [
               %{
                 y: 0,
                 segments: [
                   %{attrs: %{"bg" => 2}, x: 0, width: 13}
                 ]
               },
               %{
                 y: 1,
                 segments: [
                   %{attrs: %{"bg" => "#102030"}, x: 0, width: 3}
                 ]
               }
             ]
    end
  end

  defp render_svg(asciicast) do
    Phoenix.LiveViewTest.rendered_to_string(RecordingSVG.show(%{asciicast: asciicast}))
  end
end
