defmodule Asciinema.VtTest do
  use ExUnit.Case, async: true
  alias Asciinema.Vt

  @moduletag :vt

  describe "terminal size bounds" do
    test "accepts minimum and maximum sizes" do
      for {cols, rows} <- [{1, 1}, {720, 200}] do
        assert {:ok, vt} = Vt.new(cols, rows, 0)
        assert :ok = Vt.resize(vt, 80, 24)
        assert :ok = Vt.resize(vt, cols, rows)
        {lines, _} = Vt.dump_screen(vt)
        assert length(lines) == rows
        assert [{text, %{}, 1}] = hd(lines)
        assert String.length(text) == cols
      end
    end

    test "rejects invalid sizes without changing the terminal" do
      {:ok, vt} = Vt.new(80, 24, 0)
      :ok = Vt.feed(vt, "before")
      screen = Vt.dump_screen(vt)

      for {cols, rows} <- [{0, 24}, {80, 0}, {721, 24}, {80, 201}] do
        assert Vt.new(cols, rows, 0) == {:error, :invalid_size}
        assert Vt.resize(vt, cols, rows) == {:error, :invalid_size}
        assert Vt.dump_screen(vt) == screen
      end

      assert :ok = Vt.resize(vt, 81, 25)
      assert :ok = Vt.feed(vt, " after")
      assert Vt.text(vt) == "before after\n"
    end
  end

  describe "vt" do
    test "rejects zero dimensions" do
      assert Vt.new(0, 3, nil) == {:error, :invalid_size}
      assert Vt.new(8, 0, 0) == {:error, :invalid_size}
    end

    test "exports colors, attributes, and wide-character chunks" do
      {:ok, vt} = Vt.new(8, 1, 0)

      Vt.feed(vt, "\x1b[1;3;4;5;7;9;38;5;123;48;2;1;2;3mA界文")
      Vt.feed(vt, "\x1b[0;2;38;2;16;32;48;48;5;234mB\x1b[0m!")

      attrs = %{
        "fg" => 123,
        "bg" => "#010203",
        "bold" => true,
        "italic" => true,
        "underline" => true,
        "blink" => true,
        "inverse" => true,
        "strikethrough" => true
      }

      assert Vt.dump_screen(vt) ==
               {[
                  [
                    {"A", attrs, 1},
                    {"界文", attrs, 2},
                    {"B", %{"fg" => "#102030", "bg" => 234, "faint" => true}, 1},
                    {"! ", %{}, 1}
                  ]
                ], {7, 0}}
    end

    test "encodes visible and hidden cursors" do
      {:ok, vt} = Vt.new(4, 2, 0)
      Vt.feed(vt, "ab")
      assert {_, {2, 0}} = Vt.dump_screen(vt)

      Vt.feed(vt, "\x1b[?25l")
      assert {_, nil} = Vt.dump_screen(vt)
    end

    test "supports unlimited, disabled, and bounded primary history" do
      for {limit, expected} <- [
            {nil, "first\nsecond\nthird\nfourth\n"},
            {0, "third\nfourth\n"},
            {1, "second\nthird\nfourth\n"}
          ] do
        {:ok, vt} = Vt.new(8, 2, limit)
        Vt.feed(vt, "first\r\nsecond\r\nthird\r\nfourth")

        assert Vt.text(vt) == expected
      end
    end

    test "exports newline-terminated text without trailing empty lines" do
      {:ok, vt} = Vt.new(8, 6, nil)
      assert Vt.text(vt) == ""

      Vt.feed(vt, "first\r\n\r\nlast\r\n\r\n")
      assert Vt.text(vt) == "first\n\nlast\n"
    end

    test "exports primary text while displaying the alternate screen" do
      {:ok, vt} = Vt.new(8, 2, nil)
      Vt.feed(vt, "first\r\nsecond\r\nthird")
      Vt.feed(vt, "\x1b[?1049h\x1b[Halt")

      assert Vt.text(vt) == "first\nsecond\nthird\n"
      assert Vt.dump_screen(vt) == {[[{"alt     ", %{}, 1}], [{"        ", %{}, 1}]], {3, 0}}
    end

    test "resizes and round-trips a screen through dump and feed" do
      {:ok, vt} = Vt.new(4, 2, 0)
      assert Vt.feed(vt, "hi") == :ok
      assert Vt.resize(vt, 8, 3) == :ok

      assert Vt.dump_screen(vt) ==
               {[[{"hi      ", %{}, 1}], [{"        ", %{}, 1}], [{"        ", %{}, 1}]], {2, 0}}

      {:ok, restored} = Vt.new(8, 3, 0)
      assert Vt.feed(restored, Vt.dump(vt)) == :ok

      assert Vt.dump_screen(restored) == Vt.dump_screen(vt)
    end

    test "replaces invalid UTF-8" do
      {:ok, vt} = Vt.new(4, 1, 0)
      assert Vt.feed(vt, <<"a", 255, "b">>) == :ok
      assert Vt.dump_screen(vt) == {[[{"a�b ", %{}, 1}]], {3, 0}}
      assert Vt.text(vt) == "a�b\n"
    end
  end
end
