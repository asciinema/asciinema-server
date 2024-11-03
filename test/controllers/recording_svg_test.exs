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
  end

  defp render_svg(asciicast) do
    Phoenix.LiveViewTest.rendered_to_string(RecordingSVG.show(%{asciicast: asciicast}))
  end
end
