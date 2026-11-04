defmodule Asciinema.FtsTest do
  use ExUnit.Case, async: true
  alias Asciinema.Fts

  @moduletag :vt

  test "accepts minimum and maximum terminal sizes" do
    for {cols, rows} <- [{1, 1}, {720, 200}] do
      assert {:ok, fts} = Fts.new(cols, rows)
      assert :ok = Fts.resize(fts, 80, 24)
      assert :ok = Fts.resize(fts, cols, rows)
      assert Fts.dump(fts) == ""
    end
  end

  test "rejects invalid sizes and remains usable" do
    {:ok, fts} = Fts.new(80, 24)
    :ok = Fts.feed(fts, "before ")

    for {cols, rows} <- [{0, 24}, {80, 0}, {721, 24}, {80, 201}] do
      assert Fts.new(cols, rows) == {:error, :invalid_size}
      assert Fts.resize(fts, cols, rows) == {:error, :invalid_size}
    end

    assert :ok = Fts.resize(fts, 81, 25)
    assert :ok = Fts.feed(fts, "after")
    assert Fts.dump(fts) == "before after "
  end
end
