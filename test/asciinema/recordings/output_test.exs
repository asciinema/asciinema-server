defmodule Asciinema.Recordings.OutputTest do
  use Asciinema.DataCase
  alias Asciinema.Recordings.Output

  describe "stdout_stream/1" do
    test "with asciicast v1 file" do
      stream = Output.stream("test/fixtures/1/asciicast.json")
      assert :ok == Stream.run(stream)
      assert [{1.234567, "foo bar"}, {6.913554, "baz qux"}] == Enum.take(stream, 2)
    end

    test "with asciicast v2 file" do
      stream = Output.stream("test/fixtures/2/minimal.cast")
      assert :ok == Stream.run(stream)
      assert [{1.234567, "foo bar"}, {5.678987, "baz qux"}] == Enum.take(stream, 2)
    end

    test "with asciicast v2 file, with idle_time_limit" do
      stream = Output.stream("test/fixtures/2/full.cast")
      assert :ok == Stream.run(stream)

      assert [{1.234567, "foo bar"}, {3.734567, "baz qux"}, {6.234567, "żółć jaźń"}] ==
               Enum.take(stream, 3)
    end

    test "with asciicast v2 file, with blank lines" do
      stream = Output.stream("test/fixtures/2/with-blank-lines.cast")
      assert :ok == Stream.run(stream)

      assert [{1.234567, "foo bar"}, {5.678987, "baz qux"}, {8.456789, "żółć jaźń"}] ==
               Enum.to_list(stream)
    end
  end

  describe "stdout_stream/2" do
    test "with gzipped files" do
      stream = Output.stream({"test/fixtures/0.9.9/stdout.time", "test/fixtures/0.9.9/stdout"})

      assert :ok == Stream.run(stream)
      assert [{1.234567, "foobar"}, {1.358023, "baz"}] == Enum.take(stream, 2)
    end

    test "with bzipped files" do
      stream = Output.stream({"test/fixtures/0.9.8/stdout.time", "test/fixtures/0.9.8/stdout"})

      assert :ok == Stream.run(stream)
      assert [{1.234567, "foobar"}, {1.358023, "baz"}] == Enum.take(stream, 2)
    end

    test "with bzipped files (utf-8 sequence split between frames)" do
      stream =
        Output.stream(
          {"test/fixtures/0.9.8/stdout-split.time", "test/fixtures/0.9.8/stdout-split"}
        )

      assert :ok == Stream.run(stream)
      assert [{1.234567, "xxżó"}, {1.358023, "łć"}, {3.358023, "xx"}] == Enum.take(stream, 3)
    end
  end
end
