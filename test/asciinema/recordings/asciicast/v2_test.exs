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

  describe "write_header/3" do
    test "minimal" do
      path = Briefly.create!()
      file = File.open!(path, [:write, :utf8])

      assert V2.write_header(file, {99, 22}) == :ok

      :ok = File.close(file)
      content = File.read!(path)

      assert content == ~s|{"version":2,"width":99,"height":22}\n|
    end

    test "full" do
      path = Briefly.create!()
      file = File.open!(path, [:write, :utf8])

      assert V2.write_header(file, {99, 22},
               timestamp: 1_506_410_422,
               term_theme: %{
                 fg: {99, 98, 97},
                 bg: {3, 2, 1},
                 palette: [
                   {1, 2, 3},
                   {11, 12, 13},
                   {21, 22, 23},
                   {31, 32, 33},
                   {41, 42, 43},
                   {51, 52, 53},
                   {61, 62, 63},
                   {71, 72, 73}
                 ]
               },
               env: %{"SHELL" => "/usr/bin/fish"}
             ) == :ok

      :ok = File.close(file)
      content = File.read!(path)

      assert content ==
               ~s|{"version":2,"width":99,"height":22,"timestamp":1506410422,"env":{"SHELL":"/usr/bin/fish"},"theme":{"fg":"#636261","bg":"#030201","palette":"#010203:#0b0c0d:#151617:#1f2021:#292a2b:#333435:#3d3e3f:#474849"}}\n|
    end
  end

  describe "write_event/4" do
    setup do
      path = Briefly.create!()
      file = File.open!(path, [:write, :utf8])

      %{path: path, file_: file}
    end

    test "output", %{path: path, file_: file} do
      assert V2.write_event(file, 250_000, "o", "hello world") == :ok

      :ok = File.close(file)
      content = File.read!(path)

      assert content == ~s|[0.25, "o", "hello world"]\n|
    end

    test "input", %{path: path, file_: file} do
      assert V2.write_event(file, 250_000, "i", "h") == :ok

      :ok = File.close(file)
      content = File.read!(path)

      assert content == ~s|[0.25, "i", "h"]\n|
    end

    test "resize", %{path: path, file_: file} do
      assert V2.write_event(file, 250_000, "r", {81, 25}) == :ok

      :ok = File.close(file)
      content = File.read!(path)

      assert content == ~s|[0.25, "r", "81x25"]\n|
    end

    test "marker", %{path: path, file_: file} do
      assert V2.write_event(file, 250_000, "m", "intro") == :ok

      :ok = File.close(file)
      content = File.read!(path)

      assert content == ~s|[0.25, "m", "intro"]\n|
    end
  end
end
