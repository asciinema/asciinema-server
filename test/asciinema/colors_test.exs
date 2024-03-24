defmodule Asciinema.ColorsTest do
  use ExUnit.Case, async: true
  alias Asciinema.Colors

  describe "mix/3" do
    test "blends two colors using given ratio" do
      assert Colors.mix("#000000", "#222222", 0.5) == "#111111"
      assert Colors.mix("#007fff", "#ff7f00", 0.5) == "#7f7f7f"
      assert Colors.mix("#007fff", "#ff7f00", 0) == "#ff7f00"
      assert Colors.mix("#007fff", "#ff7f00", 1) == "#007fff"
      assert Colors.mix("#007fff", "rgb(255,127,0)", 0.5) == "#7f7f7f"
      assert Colors.mix("rgb(0,127,255)", "#ff7f00", 0.5) == "#7f7f7f"
    end
  end
end
