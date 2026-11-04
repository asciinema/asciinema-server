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
    test "basic usage" do
      {:ok, vt} = Vt.new(8, 3, nil)

      Vt.feed(vt, "foobar\r\n")
      Vt.feed(vt, "baz")
      Vt.feed(vt, "全\r\n")
      Vt.feed(vt, "\x1b[1;38:2:16:32:48mqux")

      assert {[
                [{"foobar  ", %{}, 1}],
                [{"baz", %{}, 1}, {"全", %{}, 2}, {"   ", %{}, 1}],
                [{"qux", %{"bold" => true, "fg" => "#102030"}, 1}, {"     ", %{}, 1}]
              ], {3, 2}} = Vt.dump_screen(vt)
    end

    test "feeding it a lot of data" do
      {:ok, vt} = Vt.new(120, 80, nil)

      Enum.each(1..100_000, fn _ ->
        Vt.feed(vt, "aaaaaaaaaaaaaaaaaaaaaaaa")
      end)

      assert {[_ | _], {120, 79}} = Vt.dump_screen(vt)
    end
  end
end
