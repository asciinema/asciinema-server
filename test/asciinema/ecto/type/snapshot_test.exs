defmodule Asciinema.Ecto.Type.SnapshotTest do
  use ExUnit.Case, async: true
  alias Asciinema.Ecto.Type.Snapshot, as: EctoSnapshot
  alias Asciinema.Recordings.Snapshot

  @lines [[["foobar", %{}]], [["bazqux", %{}]]]

  describe "cast/1" do
    test "is identity for Snapshot" do
      assert match?({:ok, %Snapshot{}}, EctoSnapshot.cast(Snapshot.new(@lines)))
    end

    test "wraps list into Snapshot" do
      assert match?({:ok, %Snapshot{}}, EctoSnapshot.cast(@lines))
    end

    test "wraps tuple into Snapshot" do
      assert match?({:ok, %Snapshot{}}, EctoSnapshot.cast({@lines, {1, 1}}))
    end
  end

  describe "load/1" do
    test "deserializes Snapshot from JSON" do
      json = Jason.encode!(@lines)
      assert match?({:ok, %Snapshot{}}, EctoSnapshot.load(json))
    end
  end

  describe "dump/1" do
    test "serializes Snapshot into JSON" do
      snapshot = Snapshot.new(@lines)
      assert match?({:ok, "[" <> _}, EctoSnapshot.dump(snapshot))
    end
  end
end
