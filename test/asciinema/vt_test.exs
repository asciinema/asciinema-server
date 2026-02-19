defmodule Asciinema.VtTest do
  use ExUnit.Case, async: true
  alias Asciinema.Vt

  @moduletag :vt

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
