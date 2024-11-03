defmodule Asciinema.Recordings.SnapshotTest do
  use ExUnit.Case, async: true
  alias Asciinema.Recordings.Snapshot

  def crop(snapshot, cols, rows) do
    snapshot
    |> Snapshot.new()
    |> Snapshot.crop(cols, rows)
    |> Map.get(:lines)
  end

  describe "regroup/2" do
    test "splits into individual chars" do
      lines = [[[" foo bar ", %{fg: 1}, 1]]]

      lines =
        lines
        |> Snapshot.new(:segments)
        |> Snapshot.regroup(:cells)
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
        |> Snapshot.regroup(:segments)
        |> Map.get(:lines)

      assert lines == [
               [
                 {" f", %{fg: 1}, 1},
                 {"oo", %{fg: 2}, 1},
                 {" bar", %{fg: 1}, 1},
                 {"连", %{fg: 1}, 2}
               ]
             ]
    end

    test "keeps special chars in their own segments" do
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
        |> Snapshot.regroup(:segments)
        |> Map.get(:lines)

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
               [{"bazqu", %{}, 1}],
               [{"alber", %{}, 1}],
               [{"balsa", %{}, 1}]
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
               [{"fooba", %{}, 1}],
               [{"bazqu", %{}, 1}],
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
               [{"fooba", %{}, 1}],
               [{"bazqu", %{}, 1}],
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

  describe "fg_coords/1" do
    test "excludes whitespace" do
      coords =
        @lines
        |> Snapshot.new()
        |> Snapshot.fg_coords()

      assert coords == [
               %{
                 y: 0,
                 segments: [
                   %{text: "foo bar", attrs: %{"bg" => 2}, x: 1, width: 7},
                   %{text: "baz", attrs: %{"bg" => 2}, x: 10, width: 3},
                   %{text: "!", attrs: %{"fg" => 1}, x: 13, width: 1}
                 ]
               },
               %{
                 y: 1,
                 segments: [
                   %{text: "qux", attrs: %{"bg" => "#102030"}, x: 0, width: 3},
                   %{text: "连", attrs: %{}, x: 3, width: 2},
                   %{text: "接", attrs: %{}, x: 5, width: 2}
                 ]
               }
             ]
    end
  end

  describe "bg_coords/1" do
    test "excludes segments with default background" do
      coords =
        @lines
        |> Snapshot.new()
        |> Snapshot.bg_coords()

      assert coords == [
               %{
                 y: 0,
                 segments: [
                   %{attrs: %{"bg" => 2}, x: 0, width: 13}
                 ]
               },
               %{
                 y: 1,
                 segments: [
                   %{attrs: %{"bg" => "#102030"}, x: 0, width: 3}
                 ]
               }
             ]
    end
  end

  describe "seq/1" do
    test "dumps snapshot as an ANSI sequence" do
      seq =
        @lines
        |> Snapshot.new()
        |> Snapshot.seq()

      assert seq == "\e[42m foo bar  baz\e[0m\e[31m!\e[0m\r\n\e[48;2;16;32;48mqux\e[0m连接\e[?25l"
    end
  end
end
