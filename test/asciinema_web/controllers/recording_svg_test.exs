defmodule AsciinemaWeb.RecordingSvgTest do
  use ExUnit.Case, async: true
  alias Asciinema.Recordings.Snapshot
  alias AsciinemaWeb.RecordingSVG
  import Asciinema.Factory

  describe "show/1" do
    test "renders SVG document" do
      asciicast =
        build(:asciicast, snapshot: Snapshot.new([[["foobar", %{}, 1]], [["bazqux", %{}, 1]]]))

      svg = render_svg(asciicast)

      assert svg =~ ~r/^<\?xml.+foobar.+bazqux/s
    end

    test "supports RGB color in fg/bg text attrs" do
      asciicast =
        build(:asciicast,
          snapshot:
            Snapshot.new([
              [["foo", %{"fg" => [16, 32, 48]}, 1], ["bar", %{"bg" => "rgb(64,80,96)"}, 1]],
              [["baz", %{"fg" => "#708090"}, 1]]
            ])
        )

      svg = render_svg(asciicast)

      assert svg =~ "#102030"
      assert svg =~ "rgb(64,80,96)"
      assert svg =~ "#708090"
    end
  end

  defp render_svg(asciicast) do
    Phoenix.LiveViewTest.rendered_to_string(RecordingSVG.show(%{asciicast: asciicast}))
  end
end
