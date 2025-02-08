defmodule Asciinema.Recordings.EventStreamTest do
  use Asciinema.DataCase
  alias Asciinema.Recordings.EventStream

  describe "new/1" do
    test "with asciicast v1 file" do
      stream = EventStream.new("test/fixtures/1/asciicast.json")

      assert :ok == Stream.run(stream)
      assert [{1.234567, "o", "foo bar"}, {6.913554, "o", "baz qux"}] == Enum.take(stream, 2)
    end

    test "with asciicast v2 file" do
      stream = EventStream.new("test/fixtures/2/minimal.cast")

      assert :ok == Stream.run(stream)
      assert [{1.234567, "o", "foo bar"}, {5.678987, "o", "baz qux"}] == Enum.take(stream, 2)
    end

    test "with asciicast v2 file, with idle_time_limit" do
      stream = EventStream.new("test/fixtures/2/full.cast")

      assert :ok == Stream.run(stream)

      assert [{1.234567, "o", "foo bar"}, {2.34567, "i", "\r"}, {4.84567, "o", "baz qux"}] ==
               Enum.take(stream, 3)
    end

    test "with asciicast v2 file, with blank lines" do
      stream = EventStream.new("test/fixtures/2/with-blank-lines.cast")

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
