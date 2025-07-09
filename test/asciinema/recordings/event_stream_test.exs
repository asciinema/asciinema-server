defmodule Asciinema.Recordings.EventStreamTest do
  use ExUnit.Case, async: true
  alias Asciinema.Recordings.EventStream

  describe "to_absolute_time/1" do
    test "transforms relative timestamps to absolute" do
      stream = [{0.0, "o", "a"}, {1.0, "o", "b"}, {0.5, "o", "c"}, {2.345, "o", "d"}]

      stream =
        stream
        |> EventStream.to_absolute_time()
        |> Enum.to_list()

      assert stream == [{0.0, "o", "a"}, {1.0, "o", "b"}, {1.5, "o", "c"}, {3.845, "o", "d"}]
    end
  end

  describe "to_relative_time/1" do
    test "transforms absolute timestamps to relative" do
      stream = [{0.0, "o", "a"}, {1.0, "o", "b"}, {1.5, "o", "c"}, {3.845, "o", "d"}]

      stream =
        stream
        |> EventStream.to_relative_time()
        |> Enum.to_list()

      assert stream == [{0.0, "o", "a"}, {1.0, "o", "b"}, {0.5, "o", "c"}, {2.345, "o", "d"}]
    end
  end

  describe "cap_relative_time/2" do
    test "caps relative time to a given limit" do
      stream = [{0.0, "o", "a"}, {1.0, "o", "b"}, {2.5, "o", "c"}, {0.5, "o", "d"}]

      stream =
        stream
        |> EventStream.cap_relative_time(2)
        |> Enum.to_list()

      assert stream == [{0.0, "o", "a"}, {1.0, "o", "b"}, {2.0, "o", "c"}, {0.5, "o", "d"}]
    end
  end
end
