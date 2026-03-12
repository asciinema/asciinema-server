defmodule Asciinema.Ecto.Type.SnapshotTest do
  use ExUnit.Case, async: true
  alias Asciinema.Ecto.Type.Snapshot, as: EctoSnapshot
  alias Asciinema.Recordings.Snapshot

  @segment_lines [
    [["ab", %{"fg" => 1}, 1], ["全", %{"fg" => 1}, 2], ["c", %{}, 1]],
    [["xy", %{"bg" => "#102030"}, 1], ["z", %{}, 1]]
  ]

  describe "cast/1" do
    test "builds a snapshot and applies cursor inversion" do
      assert {:ok, snapshot} = EctoSnapshot.cast({@segment_lines, {2, 0}})

      assert cells(snapshot) == [
               [
                 {"a", %{"fg" => 1}, 1},
                 {"b", %{"fg" => 1}, 1},
                 {"全", %{"fg" => 1, "inverse" => true}, 2},
                 {"c", %{}, 1}
               ],
               [
                 {"x", %{"bg" => "#102030"}, 1},
                 {"y", %{"bg" => "#102030"}, 1},
                 {"z", %{}, 1}
               ]
             ]
    end
  end

  describe "load/1" do
    test "deserializes JSON into a snapshot with the expected cells" do
      json = Jason.encode!(@segment_lines)

      assert {:ok, snapshot} = EctoSnapshot.load(json)

      assert cells(snapshot) == [
               [
                 {"a", %{"fg" => 1}, 1},
                 {"b", %{"fg" => 1}, 1},
                 {"全", %{"fg" => 1}, 2},
                 {"c", %{}, 1}
               ],
               [
                 {"x", %{"bg" => "#102030"}, 1},
                 {"y", %{"bg" => "#102030"}, 1},
                 {"z", %{}, 1}
               ]
             ]
    end
  end

  describe "dump/1" do
    test "serializes a snapshot into grouped segments" do
      snapshot =
        Snapshot.new([
          [
            {"a", %{"fg" => 1}, 1},
            {"b", %{"fg" => 1}, 1},
            {"全", %{"fg" => 1}, 2},
            {"c", %{"fg" => 1}, 1},
            {"d", %{"bg" => "#102030"}, 1},
            {"e", %{"bg" => "#102030"}, 1}
          ]
        ])

      assert {:ok, json} = EctoSnapshot.dump(snapshot)

      assert Jason.decode!(json) == [
               [
                 ["ab", %{"fg" => 1}, 1],
                 ["全", %{"fg" => 1}, 2],
                 ["c", %{"fg" => 1}, 1],
                 ["de", %{"bg" => "#102030"}, 1]
               ]
             ]
    end

    test "round-trips through dump and load" do
      snapshot =
        Snapshot.new([
          [
            {"a", %{"fg" => 1}, 1},
            {"b", %{"fg" => 1}, 1},
            {"全", %{"fg" => 1}, 2},
            {"c", %{}, 1}
          ],
          [
            {"x", %{"bg" => "#102030"}, 1},
            {"y", %{"bg" => "#102030"}, 1},
            {"z", %{}, 1}
          ]
        ])

      assert {:ok, json} = EctoSnapshot.dump(snapshot)
      assert {:ok, loaded_snapshot} = EctoSnapshot.load(json)

      assert cells(loaded_snapshot) == cells(snapshot)
    end
  end

  defp cells(snapshot) do
    for line <- snapshot do
      for {_x, cp, attrs, width} <- line, do: {<<cp::utf8>>, attrs, width}
    end
  end
end
