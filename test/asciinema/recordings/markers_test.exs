defmodule Asciinema.Recordings.MarkersTest do
  use ExUnit.Case, async: true
  alias Asciinema.Recordings.Markers

  describe "parse_markers/1" do
    test "returns markers for valid syntax" do
      result = Markers.parse("1.0 - Intro\n2.5\n5.0 - Tips & Tricks\n")

      assert result == {:ok, [{1.0, "Intro"}, {2.5, ""}, {5.0, "Tips & Tricks"}]}
    end

    test "returns error for invalid syntax" do
      result = Markers.parse("1.0 - Intro\nFoobar\n")

      assert result == {:error, 1}
    end
  end
end
