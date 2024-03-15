defmodule Asciinema.Recordings.SnapshotTest do
  use ExUnit.Case, async: true
  alias Asciinema.Recordings.Snapshot

  def window(snapshot, cols, rows) do
    snapshot
    |> Snapshot.new()
    |> Snapshot.window(cols, rows)
  end

  describe "window/3" do
    test "blank taller terminal" do
      assert window(
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
      assert window(
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
      assert window(
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
      assert window(
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
      assert window(
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
end
