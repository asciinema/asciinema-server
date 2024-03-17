defmodule Asciinema.Recordings.SnapshotTest do
  use ExUnit.Case, async: true
  alias Asciinema.Recordings.Snapshot

  def crop(snapshot, cols, rows) do
    snapshot
    |> Snapshot.new()
    |> Snapshot.crop(cols, rows)
    |> Map.get(:lines)
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
                 [],
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
    [[" foo bar ", %{"bg" => 2}, 1], ["!", %{"fg" => 1}, 1]],
    [["baz", %{"bg" => 2}, 1], ["连", %{}, 2], ["接", %{}, 2]]
  ]

  describe "text_coords/1" do
    test "excludes whitespace" do
      coords =
        @lines
        |> Snapshot.new()
        |> Snapshot.text_coords()

      assert coords == [
               %{
                 y: 0,
                 segments: [
                   %{text: "foo", attrs: %{"bg" => 2}, x: 1, width: 3},
                   %{text: "bar", attrs: %{"bg" => 2}, x: 5, width: 3},
                   %{text: "!", attrs: %{"fg" => 1}, x: 9, width: 1}
                 ]
               },
               %{
                 y: 1,
                 segments: [
                   %{text: "baz", attrs: %{"bg" => 2}, x: 0, width: 3},
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
                   %{attrs: %{"bg" => 2}, x: 0, width: 9}
                 ]
               },
               %{
                 y: 1,
                 segments: [
                   %{attrs: %{"bg" => 2}, x: 0, width: 3}
                 ]
               }
             ]
    end
  end
end
