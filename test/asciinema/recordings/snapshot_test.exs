defmodule Asciinema.Recordings.SnapshotTest do
  use ExUnit.Case, async: true
  alias Asciinema.Recordings.Snapshot

  describe "new/1" do
    test "stores cells densely and exposes them via Enumerable" do
      lines = [[[" foo bar ", %{fg: 1}, 1]]]

      lines =
        lines
        |> snapshot()
        |> cells()

      assert lines == [
               [
                 {" ", %{fg: 1}, 1},
                 {"f", %{fg: 1}, 1},
                 {"o", %{fg: 1}, 1},
                 {"o", %{fg: 1}, 1},
                 {" ", %{fg: 1}, 1},
                 {"b", %{fg: 1}, 1},
                 {"a", %{fg: 1}, 1},
                 {"r", %{fg: 1}, 1},
                 {" ", %{fg: 1}, 1}
               ]
             ]
    end
  end

  describe "build/2" do
    test "inverts the cursor cell after a wide char" do
      snapshot =
        Snapshot.build({
          segment_lines_to_cells([[["a", %{}, 1], ["全", %{}, 2], ["b", %{}, 1]]]),
          {3, 0}
        })

      assert cells(snapshot) == [
               [
                 {"a", %{}, 1},
                 {"全", %{}, 2},
                 {"b", %{"inverse" => true}, 1}
               ]
             ]
    end

    test "inverts the wide char when cursor points inside it" do
      snapshot =
        Snapshot.build({
          segment_lines_to_cells([[["a", %{}, 1], ["全", %{}, 2], ["b", %{}, 1]]]),
          {2, 0}
        })

      assert cells(snapshot) == [
               [
                 {"a", %{}, 1},
                 {"全", %{"inverse" => true}, 2},
                 {"b", %{}, 1}
               ]
             ]
    end
  end

  describe "normalize_colors/3" do
    test "inverts fg/bg colors" do
      snapshot =
        Snapshot.new([
          [
            ["A", %{"inverse" => true}, 1],
            ["B", %{"fg" => "#000000", "bg" => "#ffffff"}, 1]
          ]
        ])

      normalized = Snapshot.normalize_colors(snapshot, false, %{bg: "#000000", fg: "#ffffff"})

      assert cells(normalized) == [
               [
                 {"A", %{"fg" => "#000000", "bg" => "#ffffff"}, 1},
                 {"B", %{"fg" => "#000000", "bg" => "#ffffff"}, 1}
               ]
             ]
    end

    test "adjusts fg color when bold_is_bright" do
      snapshot =
        Snapshot.new([
          [
            ["A", %{"fg" => 1, "bold" => true}, 1],
            ["B", %{"fg" => "#000000", "bg" => "#ffffff"}, 1]
          ]
        ])

      normalized = Snapshot.normalize_colors(snapshot, true, %{bg: "#000000", fg: "#ffffff"})

      assert cells(normalized) == [
               [
                 {"A", %{"fg" => 9, "bold" => true}, 1},
                 {"B", %{"fg" => "#000000", "bg" => "#ffffff"}, 1}
               ]
             ]
    end
  end

  describe "crop/3" do
    test "blank taller terminal" do
      assert crop(
               [
                 [],
                 []
               ],
               5,
               1
             ) == [
               []
             ]
    end

    test "blank shorter terminal" do
      assert crop(
               [
                 []
               ],
               5,
               2
             ) == [
               [],
               []
             ]
    end

    test "taller terminal" do
      assert crop(
               [
                 [["foobar", %{}, 1]],
                 [["bazquxquux", %{}, 1]],
                 [["alberto", %{}, 1]],
                 [["balsam", %{}, 1]]
               ],
               5,
               3
             ) == [
               [
                 {"b", %{}, 1},
                 {"a", %{}, 1},
                 {"z", %{}, 1},
                 {"q", %{}, 1},
                 {"u", %{}, 1}
               ],
               [
                 {"a", %{}, 1},
                 {"l", %{}, 1},
                 {"b", %{}, 1},
                 {"e", %{}, 1},
                 {"r", %{}, 1}
               ],
               [
                 {"b", %{}, 1},
                 {"a", %{}, 1},
                 {"l", %{}, 1},
                 {"s", %{}, 1},
                 {"a", %{}, 1}
               ]
             ]
    end

    test "taller terminal with trailing blank lines" do
      assert crop(
               [
                 [["foobar", %{}, 1]],
                 [["bazquxquux", %{}, 1]],
                 [[" ", %{fg: 5}, 1]],
                 []
               ],
               5,
               3
             ) == [
               [
                 {"f", %{}, 1},
                 {"o", %{}, 1},
                 {"o", %{}, 1},
                 {"b", %{}, 1},
                 {"a", %{}, 1}
               ],
               [
                 {"b", %{}, 1},
                 {"a", %{}, 1},
                 {"z", %{}, 1},
                 {"q", %{}, 1},
                 {"u", %{}, 1}
               ],
               []
             ]
    end

    test "shorter terminal with trailing blank lines" do
      assert crop(
               [
                 [["foobar", %{}, 1]],
                 [["bazquxquux", %{}, 1]],
                 []
               ],
               5,
               5
             ) == [
               [
                 {"f", %{}, 1},
                 {"o", %{}, 1},
                 {"o", %{}, 1},
                 {"b", %{}, 1},
                 {"a", %{}, 1}
               ],
               [
                 {"b", %{}, 1},
                 {"a", %{}, 1},
                 {"z", %{}, 1},
                 {"q", %{}, 1},
                 {"u", %{}, 1}
               ],
               [],
               [],
               []
             ]
    end
  end

  @lines [
    [[" foo bar  baz", %{"bg" => 2}, 1], ["!", %{"fg" => 1}, 1]],
    [["qux", %{"bg" => "#102030"}, 1], ["连", %{}, 2], ["接", %{}, 2]]
  ]

  describe "seq/1" do
    test "dumps snapshot as an ANSI sequence" do
      seq =
        @lines
        |> snapshot()
        |> Snapshot.seq()

      assert seq == "\e[42m foo bar  baz\e[0m\e[31m!\e[0m\r\n\e[48;2;16;32;48mqux\e[0m连接\e[?25l"
    end

    test "trims plain trailing spaces on each line" do
      seq =
        [
          [["foo", %{}, 1]],
          [["   ", %{}, 1]],
          [["bar", %{}, 1]],
          [["  ", %{}, 1]]
        ]
        |> snapshot()
        |> Snapshot.seq()

      assert seq == "foo\r\n\r\nbar\e[?25l"
    end

    test "drops trailing empty lines" do
      seq =
        [
          [["foo", %{}, 1]],
          [],
          []
        ]
        |> snapshot()
        |> Snapshot.seq()

      assert seq == "foo\e[?25l"
    end

    test "trims plain whitespace after ANSI reset at each line end" do
      seq =
        [
          [["foo", %{"fg" => 1}, 1], ["   ", %{}, 1]],
          [["foo", %{"fg" => 1}, 1], ["   ", %{}, 1]]
        ]
        |> snapshot()
        |> Snapshot.seq()

      assert seq == "\e[31mfoo\e[0m\r\n\e[31mfoo\e[0m\e[?25l"
    end
  end

  defp crop(snapshot, cols, rows) do
    snapshot
    |> snapshot()
    |> Snapshot.crop(cols, rows)
    |> cells()
  end

  defp snapshot(lines) do
    lines
    |> segment_lines_to_cells()
    |> Snapshot.new()
  end

  defp cells(snapshot) do
    for line <- snapshot do
      for {_x, cp, attrs, width} <- line, do: {<<cp::utf8>>, attrs, width}
    end
  end

  defp segment_lines_to_cells(lines) do
    Enum.map(lines, fn line ->
      Enum.flat_map(line, fn
        [text, attrs, width] -> Enum.map(String.codepoints(text), &{&1, attrs, width})
        [text, attrs] -> Enum.map(String.codepoints(text), &{&1, attrs, 1})
        {text, attrs, width} -> Enum.map(String.codepoints(text), &{&1, attrs, width})
        {text, attrs} -> Enum.map(String.codepoints(text), &{&1, attrs, 1})
      end)
    end)
  end
end
