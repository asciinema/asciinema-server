defmodule Asciinema.Recordings.SnapshotTest do
  use ExUnit.Case, async: true
  alias Asciinema.Recordings.Snapshot

  describe "from_segments/2" do
    test "stores cells densely and exposes them via Enumerable" do
      rows = [[[" foo bar ", %{fg: 1}, 1]]]

      rows =
        rows
        |> snapshot()
        |> cells()

      assert rows == [
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

  describe "cursor preservation" do
    test "preserves the cursor after a wide char" do
      snapshot =
        Snapshot.from_segments(
          [[["a", %{}, 1], ["全", %{}, 2], ["b", %{}, 1]]],
          {3, 0}
        )

      assert snapshot.cursor == {3, 0}

      assert cells(snapshot) == [
               [
                 {"a", %{}, 1},
                 {"全", %{}, 2},
                 {"b", %{}, 1}
               ]
             ]
    end

    test "preserves the exact column inside a wide char" do
      snapshot =
        Snapshot.from_segments(
          [[["a", %{}, 1], ["全", %{}, 2], ["b", %{}, 1]]],
          {2, 0}
        )

      assert snapshot.cursor == {2, 0}

      assert cells(snapshot) == [
               [
                 {"a", %{}, 1},
                 {"全", %{}, 2},
                 {"b", %{}, 1}
               ]
             ]
    end
  end

  describe "normalize_colors/3" do
    test "normalizes attributes without rebuilding rows or moving the cursor" do
      snapshot =
        Snapshot.from_segments(
          [[{"a", %{"inverse" => true}, 1}, {"b", %{"fg" => "#000", "bg" => "#fff"}, 1}]],
          {1, 0}
        )

      normalized = Snapshot.normalize_colors(snapshot, false, %{bg: "#000", fg: "#fff"})
      assert normalized.rows == snapshot.rows
      assert normalized.cursor == {1, 0}
      assert elem(normalized.attrs, 0) == elem(normalized.attrs, 1)
      assert Snapshot.to_segments(normalized) == [[["ab", %{"fg" => "#000", "bg" => "#fff"}, 1]]]
    end

    test "inverts fg/bg colors" do
      snapshot =
        Snapshot.from_segments([
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
        Snapshot.from_segments([
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

  describe "crop_for_thumbnail/3" do
    test "retains a blank cursor row and rebases its coordinates" do
      snapshot =
        Snapshot.from_segments(
          [[{"a", %{}, 1}], [{"b", %{}, 1}], [{"   ", %{}, 1}], []],
          {2, 2}
        )
        |> Snapshot.crop_for_thumbnail(3, 2)

      assert snapshot.cursor == {2, 1}
      assert Snapshot.to_segments(snapshot) == [[["b", %{}, 1]], [["   ", %{}, 1]]]
    end

    test "removes cursors outside either cropped dimension" do
      rows = [[{"abc", %{}, 1}], [{"def", %{}, 1}], [{"ghi", %{}, 1}]]

      for cursor <- [{2, 1}, {0, 0}] do
        cropped = Snapshot.from_segments(rows, cursor) |> Snapshot.crop_for_thumbnail(2, 2)
        assert cropped.cursor == nil
      end
    end

    test "clips wide characters in display columns preserving their background" do
      snapshot =
        Snapshot.from_segments([[{"a", %{}, 1}, {"全", %{"bg" => 2}, 2}, {"b", %{}, 1}]], {1, 0})
        |> Snapshot.crop_for_thumbnail(2, 1)

      assert Snapshot.to_segments(snapshot) == [[["a", %{}, 1], [" ", %{"bg" => 2}, 1]]]
      assert snapshot.cursor == {1, 0}
    end

    test "retains inverse-video blank rows" do
      snapshot =
        Snapshot.from_segments([[{"x", %{}, 1}], [{" ", %{"inverse" => true}, 1}], []])
        |> Snapshot.crop_for_thumbnail(1, 1)

      assert Snapshot.to_segments(snapshot) == [[[" ", %{"inverse" => true}, 1]]]
    end

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

    test "taller terminal with trailing blank rows" do
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

    test "shorter terminal with trailing blank rows" do
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

  @rows [
    [[" foo bar  baz", %{"bg" => 2}, 1], ["!", %{"fg" => 1}, 1]],
    [["qux", %{"bg" => "#102030"}, 1], ["连", %{}, 2], ["接", %{}, 2]]
  ]

  describe "to_ansi/1" do
    test "round-trips a captured pending-wrap cursor at the last visible column" do
      {:ok, vt} = Asciinema.Vt.new(3, 1, 0)
      Asciinema.Vt.feed(vt, "abc")
      {rows, cursor} = Asciinema.Vt.dump_screen(vt)
      snapshot = Snapshot.from_segments(rows, cursor)

      {:ok, replay} = Asciinema.Vt.new(3, 1, 0)
      Asciinema.Vt.feed(replay, Snapshot.to_ansi(snapshot))

      assert Asciinema.Vt.dump_screen(replay) == {[[{"abc", %{}, 1}]], {2, 0}}
    end

    test "restores content and a cursor inside a wide character" do
      snapshot =
        Snapshot.from_segments(
          [[{"a", %{"fg" => 2}, 1}, {"全", %{"fg" => 2}, 2}, {"b", %{"inverse" => true}, 1}]],
          {2, 0}
        )

      {:ok, vt} = Asciinema.Vt.new(5, 2, 0)
      Asciinema.Vt.feed(vt, Snapshot.to_ansi(snapshot))
      {rows, cursor} = Asciinema.Vt.dump_screen(vt)
      assert cursor == {2, 0}

      assert rows == [
               [
                 {"a", %{"fg" => 2}, 1},
                 {"全", %{"fg" => 2}, 2},
                 {"b", %{"inverse" => true}, 1},
                 {" ", %{}, 1}
               ],
               [{"     ", %{}, 1}]
             ]
    end

    test "positions a cursor on otherwise trimmed blank rows" do
      snapshot = Snapshot.from_segments([[{"a", %{}, 1}], [], []], {2, 2})
      assert Snapshot.to_ansi(snapshot) == "a\e[3;3H\e[?25h"
    end

    test "dumps snapshot as an ANSI sequence" do
      seq =
        @rows
        |> snapshot()
        |> Snapshot.to_ansi()

      assert seq == "\e[42m foo bar  baz\e[0m\e[31m!\e[0m\r\n\e[48;2;16;32;48mqux\e[0m连接\e[?25l"
    end

    test "trims plain trailing spaces on each row" do
      seq =
        [
          [["foo", %{}, 1]],
          [["   ", %{}, 1]],
          [["bar", %{}, 1]],
          [["  ", %{}, 1]]
        ]
        |> snapshot()
        |> Snapshot.to_ansi()

      assert seq == "foo\r\n\r\nbar\e[?25l"
    end

    test "drops trailing empty rows" do
      seq =
        [
          [["foo", %{}, 1]],
          [],
          []
        ]
        |> snapshot()
        |> Snapshot.to_ansi()

      assert seq == "foo\e[?25l"
    end

    test "trims plain whitespace after ANSI reset at each row end" do
      seq =
        [
          [["foo", %{"fg" => 1}, 1], ["   ", %{}, 1]],
          [["foo", %{"fg" => 1}, 1], ["   ", %{}, 1]]
        ]
        |> snapshot()
        |> Snapshot.to_ansi()

      assert seq == "\e[31mfoo\e[0m\r\n\e[31mfoo\e[0m\e[?25l"
    end
  end

  defp crop(snapshot, cols, rows) do
    snapshot
    |> snapshot()
    |> Snapshot.crop_for_thumbnail(cols, rows)
    |> cells()
  end

  defp snapshot(rows) do
    Snapshot.from_segments(rows)
  end

  defp cells(snapshot) do
    for row <- snapshot do
      for {_x, cp, attrs, width} <- row, do: {<<cp::utf8>>, attrs, width}
    end
  end
end
