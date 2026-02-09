defmodule Asciinema.Recordings.SnapshotTest do
  use ExUnit.Case, async: true
  alias Asciinema.Recordings.Snapshot

  def crop(snapshot, cols, rows) do
    snapshot
    |> Snapshot.new(:segments)
    |> Snapshot.crop(cols, rows)
    |> Map.get(:lines)
  end

  describe "segments_to_cells/1" do
    test "splits into individual chars" do
      lines = [[[" foo bar ", %{fg: 1}, 1]]]

      lines =
        lines
        |> Snapshot.new(:segments)
        |> Map.get(:lines)

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

  describe "to_segments/1" do
    test "groups into multi-char segments" do
      lines = [
        [
          [" ", %{fg: 1}, 1],
          ["f", %{fg: 1}, 1],
          ["o", %{fg: 2}, 1],
          ["o", %{fg: 2}, 1],
          [" ", %{fg: 1}, 1],
          ["b", %{fg: 1}, 1],
          ["a", %{fg: 1}, 1],
          ["r", %{fg: 1}, 1],
          ["连", %{fg: 1}, 2]
        ]
      ]

      lines =
        lines
        |> Snapshot.new(:cells)
        |> Snapshot.to_segments()

      assert lines == [
               [
                 {" f", %{fg: 1}, 1},
                 {"oo", %{fg: 2}, 1},
                 {" bar", %{fg: 1}, 1},
                 {"连", %{fg: 1}, 2}
               ]
             ]
    end

    test "keeps special chars in their own segments when split_specials is true" do
      lines = [
        [
          ["▚", %{}, 1],
          ["f", %{}, 1],
          ["o", %{}, 1],
          ["o", %{}, 1],
          ["▚", %{}, 1],
          ["b", %{}, 1],
          ["a", %{}, 1],
          ["r", %{}, 1],
          ["▚", %{}, 1]
        ]
      ]

      lines =
        lines
        |> Snapshot.new(:cells)
        |> Snapshot.to_segments(split_specials: true)

      assert lines == [
               [
                 {"▚", %{}, 1},
                 {"foo", %{}, 1},
                 {"▚", %{}, 1},
                 {"bar", %{}, 1},
                 {"▚", %{}, 1}
               ]
             ]
    end

    test "keeps black square in its own segment when split_specials is true" do
      lines = [
        [
          ["a", %{}, 1],
          ["■", %{}, 1],
          ["b", %{}, 1]
        ]
      ]

      lines =
        lines
        |> Snapshot.new(:cells)
        |> Snapshot.to_segments(split_specials: true)

      assert lines == [
               [
                 {"a", %{}, 1},
                 {"■", %{}, 1},
                 {"b", %{}, 1}
               ]
             ]
    end
  end

  describe "build/2" do
    test "inverts the cursor cell after a wide char" do
      snapshot =
        Snapshot.build(
          {[[["a", %{}, 1], ["全", %{}, 2], ["b", %{}, 1]]], {3, 0}},
          :segments
        )

      assert snapshot.lines == [
               [
                 {"a", %{}, 1},
                 {"全", %{}, 2},
                 {"b", %{"inverse" => true}, 1}
               ]
             ]
    end

    test "inverts the wide char when cursor points inside it" do
      snapshot =
        Snapshot.build(
          {[[["a", %{}, 1], ["全", %{}, 2], ["b", %{}, 1]]], {2, 0}},
          :segments
        )

      assert snapshot.lines == [
               [
                 {"a", %{}, 1},
                 {"全", %{"inverse" => true}, 2},
                 {"b", %{}, 1}
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
        |> Snapshot.new(:segments)
        |> Snapshot.seq()

      assert seq == "\e[42m foo bar  baz\e[0m\e[31m!\e[0m\r\n\e[48;2;16;32;48mqux\e[0m连接\e[?25l"
    end
  end
end
