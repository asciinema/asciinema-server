defmodule Asciinema.Recordings.Asciicast.V3Test do
  use Asciinema.DataCase
  alias Asciinema.Recordings.Asciicast.V3

  describe "fetch_metadata/1" do
    test "minimal" do
      {:ok, metadata} = V3.fetch_metadata("test/fixtures/3/minimal.cast")

      assert metadata == %{
               version: 3,
               term_cols: 96,
               term_rows: 26,
               term_type: nil,
               term_version: nil,
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
      {:ok, metadata} = V3.fetch_metadata("test/fixtures/3/full.cast")

      assert metadata == %{
               version: 3,
               term_cols: 96,
               term_rows: 26,
               term_type: "xterm-ghostty",
               term_version: "ghostty 1.1.3-889478f-nix",
               term_theme_fg: "#aaaaaa",
               term_theme_bg: "#bbbbbb",
               term_theme_palette:
                 "#151515:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#d0d0d0:#505050:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#f5f5f5",
               command: "/bin/bash -l",
               duration: 8.191356,
               recorded_at: ~U[2025-04-10 16:20:22Z],
               title: "bashing :)",
               env: %{
                 "TERM" => "xterm-ghostty",
                 "SHELL" => "/usr/bin/fish"
               },
               idle_time_limit: 2.5,
               shell: "/usr/bin/fish"
             }
    end
  end

  describe "event_stream/1" do
    test "minimal" do
      stream = V3.event_stream("test/fixtures/3/minimal.cast")

      assert Enum.take(stream, 2) == [{1.234567, "o", "foo bar"}, {5.654321, "o", "baz qux"}]
    end

    test "with idle_time_limit" do
      stream = V3.event_stream("test/fixtures/3/full.cast")

      assert Enum.take(stream, 5) == [
               {1.234567, "o", "foo bar"},
               {2.234567, "i", "\r"},
               {4.734567, "o", "baz qux"},
               {5.734567, "r", "80x24"},
               {8.191356, "o", "żółć jaźń"}
             ]
    end

    test "with blank lines and comments" do
      stream = V3.event_stream("test/fixtures/3/blank-lines-and-comments.cast")

      assert Enum.to_list(stream) == [
               {1.234567, "o", "foo bar"},
               {5.678987, "o", "baz qux"},
               {8.481455, "o", "żółć jaźń"},
               {9.481455, "o", "bye!"}
             ]
    end
  end

  describe "create/3" do
    test "minimal header" do
      path = Briefly.create!()

      {:ok, writer} = V3.create(path, {99, 22})

      :ok = V3.close(writer)
      content = File.read!(path)

      assert content == ~s|{"version":3,"term":{"cols":99,"rows":22}}\n|
    end

    test "full header" do
      path = Briefly.create!()

      {:ok, writer} =
        V3.create(path, {99, 22},
          timestamp: 1_744_302_022,
          term_type: "xterm-ghostty",
          term_version: "ghostty 1.1.3-889478f-nix",
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
        )

      :ok = V3.close(writer)
      content = File.read!(path)

      assert content ==
               ~s|{"version":3,"term":{"cols":99,"rows":22,"type":"xterm-ghostty","version":"ghostty 1.1.3-889478f-nix","theme":{"fg":"#636261","bg":"#030201","palette":"#010203:#0b0c0d:#151617:#1f2021:#292a2b:#333435:#3d3e3f:#474849"}},"timestamp":1744302022,"env":{"SHELL":"/usr/bin/fish"}}\n|
    end
  end

  describe "write_event/4" do
    setup do
      path = Briefly.create!()
      {:ok, writer} = V3.create(path, {99, 22})

      %{path: path, writer: writer}
    end

    test "output", %{path: path, writer: writer} do
      {:ok, writer} = V3.write_event(writer, 250_000, "o", "hello world")
      :ok = V3.close(writer)
      content = File.read!(path)

      assert content ==
               ~s|{"version":3,"term":{"cols":99,"rows":22}}\n[0.25, "o", "hello world"]\n|
    end

    test "input", %{path: path, writer: writer} do
      {:ok, writer} = V3.write_event(writer, 1_000_000, "i", "h")
      :ok = V3.close(writer)
      content = File.read!(path)

      assert content == ~s|{"version":3,"term":{"cols":99,"rows":22}}\n[1.0, "i", "h"]\n|
    end

    test "resize", %{path: path, writer: writer} do
      {:ok, writer} = V3.write_event(writer, 10000, "r", {81, 25})
      :ok = V3.close(writer)
      content = File.read!(path)

      assert content == ~s|{"version":3,"term":{"cols":99,"rows":22}}\n[0.01, "r", "81x25"]\n|
    end

    test "marker", %{path: path, writer: writer} do
      {:ok, writer} = V3.write_event(writer, 123_456_789, "m", "intro")
      :ok = V3.close(writer)
      content = File.read!(path)

      assert content ==
               ~s|{"version":3,"term":{"cols":99,"rows":22}}\n[123.456789, "m", "intro"]\n|
    end
  end

  describe "complete file" do
    test "relative timestamps" do
      path = Briefly.create!()

      {:ok, writer} = V3.create(path, {99, 22})
      {:ok, writer} = V3.write_event(writer, 250_000, "o", "hello world")
      {:ok, writer} = V3.write_event(writer, 1_000_000, "i", "h")
      {:ok, writer} = V3.write_event(writer, 1_500_000, "r", {81, 25})
      {:ok, writer} = V3.write_event(writer, 2_000_050, "m", "intro")
      :ok = V3.close(writer)
      content = File.read!(path)

      assert content ==
               ~s|{"version":3,"term":{"cols":99,"rows":22}}\n[0.25, "o", "hello world"]\n[0.75, \"i\", \"h\"]\n[0.5, \"r\", \"81x25\"]\n[0.50005, \"m\", \"intro\"]\n|
    end
  end
end
