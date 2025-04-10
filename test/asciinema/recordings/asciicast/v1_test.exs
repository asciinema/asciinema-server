defmodule Asciinema.Recordings.Asciicast.V1Test do
  use Asciinema.DataCase
  alias Asciinema.Recordings.Asciicast.V1

  describe "fetch_metadata/1" do
    test "minimal" do
      {:ok, metadata} = V1.fetch_metadata("test/fixtures/1/minimal.json")

      assert metadata == %{
               version: 1,
               term_cols: 96,
               term_rows: 26,
               term_type: nil,
               command: nil,
               duration: 8.456789,
               title: nil,
               env: %{},
               shell: nil
             }
    end

    test "full" do
      {:ok, metadata} = V1.fetch_metadata("test/fixtures/1/full.json")

      assert metadata == %{
               version: 1,
               term_cols: 96,
               term_rows: 26,
               term_type: "screen-256color",
               command: "/bin/bash",
               duration: 11.146430,
               title: "bashing :)",
               env: %{
                 "TERM" => "screen-256color",
                 "SHELL" => "/bin/zsh"
               },
               shell: "/bin/zsh"
             }
    end
  end

  describe "event_stream/1" do
    test "full" do
      stream = V1.event_stream("test/fixtures/1/full.json")

      assert Enum.take(stream, 2) == [{1.234567, "o", "foo bar"}, {6.913554, "o", "baz qux"}]
    end
  end
end
