defmodule Asciinema.VtTest do
  use ExUnit.Case
  alias Asciinema.Vt

  @moduletag :vt

  describe "vt" do
    test "basic usage" do
      result =
        Vt.with_vt(8, 3, fn vt ->
          Vt.feed(vt, "foobar\r\n")
          Vt.feed(vt, "baz")
          Vt.feed(vt, "全\r\n")
          Vt.feed(vt, "\x1b[1;38:2:16:32:48mqux")
          Vt.dump_screen(vt)
        end)

      assert {:ok,
              {[
                 [{"foobar  ", %{}, 1}],
                 [{"baz", %{}, 1}, {"全", %{}, 2}, {"    ", %{}, 1}],
                 [{"qux", %{"bold" => true, "fg" => "#102030"}, 1}, {"     ", %{}, 1}]
               ], {3, 2}}} = result
    end

    test "feeding it a lot of data" do
      result =
        Vt.with_vt(120, 80, fn vt ->
          Enum.each(1..300_000, fn _ ->
            Vt.feed(vt, "aaaaaaaaaaaaaaaaaaaaaaaa")
          end)

          Vt.dump_screen(vt)
        end)

      assert {:ok, {[_ | _], {120, 79}}} = result
    end
  end
end
