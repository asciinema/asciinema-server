defmodule Asciinema.Recordings.Asciicast.V2Test do
  use Asciinema.DataCase
  alias Asciinema.Recordings.Asciicast.V2

  describe "fetch_metadata/1" do
    test "minimal" do
      {:ok, metadata} = V2.fetch_metadata("test/fixtures/2/minimal.cast")

      assert metadata == %{
               version: 2,
               term_cols: 96,
               term_rows: 26,
               term_type: nil,
               term_theme_fg: nil,
               term_theme_bg: nil,
               term_theme_palette: nil,
               command: nil,
               duration: 8.456789,
               recorded_at: nil,
               title: nil,
               env: %{},
               idle_time_limit: nil,
               shell: nil
             }
    end

    test "full" do
      {:ok, metadata} = V2.fetch_metadata("test/fixtures/2/full.cast")

      assert metadata == %{
               version: 2,
               term_cols: 96,
               term_rows: 26,
               term_type: "screen-256color",
               term_theme_fg: "#aaaaaa",
               term_theme_bg: "#bbbbbb",
               term_theme_palette:
                 "#151515:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#d0d0d0:#505050:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#f5f5f5",
               command: "/bin/bash -l",
               duration: 7.34567,
               recorded_at: ~U[2017-09-26 07:20:22Z],
               title: "bashing :)",
               env: %{
                 "TERM" => "screen-256color",
                 "SHELL" => "/bin/zsh"
               },
               idle_time_limit: 2.5,
               shell: "/bin/zsh"
             }
    end
  end

  describe "event_stream/1" do
    test "minimal" do
      stream = V2.event_stream("test/fixtures/2/minimal.cast")

      assert Enum.take(stream, 2) == [{1.234567, "o", "foo bar"}, {5.678987, "o", "baz qux"}]
    end

    test "with idle_time_limit" do
      stream = V2.event_stream("test/fixtures/2/full.cast")

      assert Enum.take(stream, 3) == [
               {1.234567, "o", "foo bar"},
               {2.34567, "i", "\r"},
               {4.84567, "o", "baz qux"}
             ]
    end

    test "with blank lines" do
      stream = V2.event_stream("test/fixtures/2/blank-lines.cast")

      assert Enum.to_list(stream) == [
               {1.234567, "o", "foo bar"},
               {5.678987, "o", "baz qux"},
               {8.456789, "o", "żółć jaźń"}
             ]
    end
  end
end
