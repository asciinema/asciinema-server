defmodule Asciinema.RecordingSvgTest do
  use ExUnit.Case, async: true
  alias AsciinemaWeb.RecordingSVG
  import Asciinema.Factory

  describe "show/1" do
    test "renders SVG document" do
      asciicast = build(:asciicast, snapshot: [[["foobar", %{}]], [["bazqux", %{}]]])

      svg = render_svg(asciicast)

      assert svg =~ ~r/^<\?xml.+foobar.+bazqux/s
    end

    test "supports RGB color in fg/bg text attrs" do
      asciicast =
        build(:asciicast,
          snapshot: [
            [["foo", %{"fg" => [16, 32, 48]}], ["bar", %{"bg" => "rgb(64,80,96)"}]],
            [["baz", %{"fg" => "#708090"}]]
          ]
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
