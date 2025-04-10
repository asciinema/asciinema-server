defmodule Asciinema.Recordings.Asciicast.V1Test do
  use Asciinema.DataCase
  alias Asciinema.Recordings.Asciicast.V1

  describe "event_stream/1" do
    test "basic" do
      stream = V1.event_stream("test/fixtures/1/asciicast.json")

      assert :ok == Stream.run(stream)
      assert [{1.234567, "o", "foo bar"}, {6.913554, "o", "baz qux"}] == Enum.take(stream, 2)
    end
  end
end
