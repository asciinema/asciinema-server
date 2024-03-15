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
          Vt.feed(vt, "qux")
          Vt.dump_screen(vt)
        end)

      assert {:ok,
              {[[{"foobar  ", %{}, 1}], [{"bazqux  ", %{}, 1}], [{"        ", %{}, 1}]], {6, 1}}} =
               result
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
