defmodule Asciinema.Recordings.Asciicast.V2Test do
  use Asciinema.DataCase
  alias Asciinema.Recordings.Asciicast.V2

  describe "event_stream/1" do
    test "basic" do
      stream = V2.event_stream("test/fixtures/2/minimal.cast")

      assert :ok == Stream.run(stream)
      assert [{1.234567, "o", "foo bar"}, {5.678987, "o", "baz qux"}] == Enum.take(stream, 2)
    end

    test "with idle_time_limit" do
      stream = V2.event_stream("test/fixtures/2/full.cast")

      assert :ok == Stream.run(stream)

      assert [{1.234567, "o", "foo bar"}, {2.34567, "i", "\r"}, {4.84567, "o", "baz qux"}] ==
               Enum.take(stream, 3)
    end

    test "with blank lines" do
      stream = V2.event_stream("test/fixtures/2/with-blank-lines.cast")

      assert :ok == Stream.run(stream)

      assert [
               {1.234567, "o", "foo bar"},
               {5.678987, "o", "baz qux"},
               {8.456789, "o", "żółć jaźń"}
             ] ==
               Enum.to_list(stream)
    end
  end
end
