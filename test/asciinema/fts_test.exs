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

  test "rejects zero dimensions" do
    assert Fts.new(0, 4) == {:error, :invalid_size}
    assert Fts.new(20, 0) == {:error, :invalid_size}
  end

  test "keeps primary text in order across eviction and a screen clear" do
    {:ok, fts} = Fts.new(16, 2)
    lines = Enum.map(1..1010, &"line#{&1}")

    assert Fts.feed(fts, Enum.join(lines, "\r\n")) == :ok
    assert Fts.feed(fts, "\x1b[H\x1b[2Jlast") == :ok
    assert Fts.dump(fts) == Enum.join(lines ++ ["last", ""], " ")
  end

  test "joins a wrapped word whose prefix was evicted before finalization" do
    {:ok, fts} = Fts.new(4, 2)

    assert Fts.feed(fts, String.duplicate("a", 4020)) == :ok
    assert Fts.feed(fts, "\r\nlast") == :ok
    assert Fts.dump(fts) == String.duplicate("a", 32) <> " last "
  end

  test "forwards hard reset observations to the transcript" do
    {:ok, fts} = Fts.new(16, 2)
    assert Fts.feed(fts, "before\x1bcafter") == :ok
    assert Fts.dump(fts) == "before after "
  end

  test "collects primary lines evicted by resize without another feed" do
    {:ok, fts} = Fts.new(16, 200)
    lines = Enum.map(1..1010, &"line#{&1}")

    assert Fts.feed(fts, Enum.join(lines, "\r\n")) == :ok
    assert Fts.resize(fts, 16, 1) == :ok
    assert Fts.dump(fts) == Enum.join(lines ++ [""], " ")
  end

  test "finalizes primary content while the alternate buffer is active" do
    {:ok, fts} = Fts.new(20, 4)

    assert Fts.feed(fts, "primary\r\n") == :ok
    assert Fts.feed(fts, "\x1b[?1049halternate") == :ok
    assert Fts.dump(fts) == "primary alternate "
  end

  test "compares alternate words at output-event boundaries" do
    {:ok, fts} = Fts.new(20, 4)

    assert Fts.feed(fts, "\x1b[?1049halpha") == :ok
    assert Fts.feed(fts, "\rbravo") == :ok
    assert Fts.dump(fts) == "alpha bravo "
  end

  test "keeps complete alternate words through edits at either end" do
    for frames <- [
          ["word", "words", "word"],
          ["word", "sword", "word"]
        ] do
      {:ok, fts} = Fts.new(40, 2)
      assert Fts.feed(fts, "\x1b[?1049h") == :ok

      for frame <- frames do
        assert Fts.feed(fts, "\r\x1b[2Kleft #{frame} right") == :ok
      end

      assert Fts.dump(fts) == "left #{Enum.at(frames, 1)} right "
    end
  end

  test "preserves removed and replaced alternate words between unchanged ends" do
    {:ok, fts} = Fts.new(40, 2)
    assert Fts.feed(fts, "\x1b[?1049hleft middle removed right") == :ok
    assert Fts.feed(fts, "\r\x1b[2Kleft replacement right") == :ok
    assert Fts.feed(fts, "\r\x1b[2Kleft replacement added right") == :ok
    assert Fts.dump(fts) == "middle removed left replacement added right "
  end

  test "handles repeated alternate words when common ends overlap" do
    {:ok, fts} = Fts.new(40, 2)
    assert Fts.feed(fts, "\x1b[?1049hsame same") == :ok
    assert Fts.feed(fts, "\r\x1b[2Ksame") == :ok
    assert Fts.feed(fts, "\r\x1b[2K") == :ok
    assert Fts.dump(fts) == "same "
  end

  test "trims pending dirty rows when the alternate screen shrinks" do
    {:ok, fts} = Fts.new(20, 4)

    assert Fts.feed(fts, "\x1b[?1049h\x1b[4;1Hbottom") == :ok
    assert Fts.resize(fts, 20, 5) == :ok
    assert Fts.resize(fts, 20, 2) == :ok
    assert Fts.feed(fts, "\x1b[Htop") == :ok
    assert Fts.dump(fts) |> String.split() |> Enum.sort() == ["bottom", "top"]
  end

  test "replaces invalid UTF-8 before indexing" do
    {:ok, fts} = Fts.new(20, 4)

    assert Fts.feed(fts, <<"before", 255, "after">>) == :ok
    assert Fts.dump(fts) == "before after "
  end

  test "splits punctuation and keeps the existing Unicode and word length rules" do
    {:ok, fts} = Fts.new(100, 2)
    text = "A--É/界 foo_bar\tBAZ " <> String.duplicate("X", 40)
    assert Fts.feed(fts, text) == :ok
    assert Fts.dump(fts) == "é 界 foo bar baz " <> String.duplicate("x", 32) <> " "
  end
end
