defmodule Asciinema.VtTest do
  use ExUnit.Case
  alias Asciinema.Vt

  @moduletag :vt

  test "Vt.Worker" do
    {:ok, pid} = Vt.Worker.start_link(nil)

    assert Vt.Worker.new(pid, 8, 3) == :ok
    assert Vt.Worker.feed(pid, "foobar\r\n") == :ok
    assert Vt.Worker.feed(pid, "baz") == :ok
    assert Vt.Worker.feed(pid, "qux") == :ok
    assert {:ok, screen} = Vt.Worker.dump_screen(pid, 1000)
    assert %{"lines" => [_ | _],
             "cursor" => %{"x" => 6,
                           "y" => 1,
                           "visible" => true}} = screen

    assert Vt.Worker.new(pid, 120, 80) == :ok
    Enum.each(1..3000, fn _ ->
      :ok = Vt.Worker.feed(pid, "aaaaaaaaaaaaaaaaaaaaaaaa")
    end)
    assert {:ok, %{"cursor" => %{"x" => 120, "y" => 79}}} = Vt.Worker.dump_screen(pid, 10000)
  end

  test "Vt" do
    {:ok, _pid} = Vt.Pool.start_link()

    result = Vt.with_vt(8, 3, fn vt ->
      :ok = Vt.feed(vt, "foobar\r\n")
      :ok = Vt.feed(vt, "baz")
      :ok = Vt.feed(vt, "qux")
      Vt.dump_screen(vt)
    end)

    assert {:ok, %{"cursor" => %{"x" => 6, "y" => 1}}} = result
  end
end
