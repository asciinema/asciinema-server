defmodule Asciinema.Recordings.Asciicast.V1Test do
  use Asciinema.DataCase
  alias Asciinema.Recordings.Asciicast.V1

  describe "fetch_metadata/1" do
    test "minimal" do
      {:ok, metadata} = V1.fetch_metadata("test/fixtures/1/minimal.json")

      assert metadata == %{
               version: 1,
               cols: 96,
               rows: 26,
               terminal_type: nil,
               command: nil,
               duration: 8.456789,
               title: nil,
               env: %{},
               shell: nil
             }
    end
  end

  describe "event_stream/1" do
    test "basic" do
      stream = V1.event_stream("test/fixtures/1/asciicast.json")

      assert :ok == Stream.run(stream)
      assert [{1.234567, "o", "foo bar"}, {6.913554, "o", "baz qux"}] == Enum.take(stream, 2)
    end
  end
end
