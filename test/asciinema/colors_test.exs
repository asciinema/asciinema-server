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

  describe "contrast_ratio/2" do
    test "calculates WCAG contrast ratios" do
      assert Colors.contrast_ratio("#000000", "#ffffff") == 21
      assert_in_delta Colors.contrast_ratio("#777777", "#ffffff"), 4.478, 0.001
      assert Colors.contrast_ratio("rgb(0,0,0)", "rgb(0,0,0)") == 1
    end
  end

  describe "mix_oklab/3" do
    test "blends colors in OKLab" do
      assert Colors.mix_oklab("#ffffff", "#000000", 0) == "#000000"
      assert Colors.mix_oklab("#ffffff", "#000000", 1) == "#ffffff"
      assert Colors.mix_oklab("#ffffff", "#000000", 0.5) == "#636363"
    end
  end

  describe "ensure_contrast/2" do
    test "preserves colors that already have enough contrast" do
      assert Colors.ensure_contrast("#cccccc", "#121314") == "#cccccc"
    end

    test "lightens or darkens colors to reach 4.5:1 contrast" do
      lightened = Colors.ensure_contrast("#657b83", "#002b36")
      darkened = Colors.ensure_contrast("#657b83", "#fdf6e3")

      assert Colors.contrast_ratio(lightened, "#002b36") >= 4.5
      assert Colors.contrast_ratio(darkened, "#fdf6e3") >= 4.5
    end

    test "measures the serialized result when correcting near the threshold" do
      corrected = Colors.ensure_contrast("#777777", "#ffffff")

      assert Colors.contrast_ratio(corrected, "#ffffff") >= 4.5
    end

    test "handles identical and saturated colors" do
      for {foreground, background} <- [
            {"#888888", "#888888"},
            {"#ff0000", "#ff0000"},
            {"#00ff00", "#00ff00"}
          ] do
        corrected = Colors.ensure_contrast(foreground, background)
        assert Colors.contrast_ratio(corrected, background) >= 4.5
      end
    end
  end
end
