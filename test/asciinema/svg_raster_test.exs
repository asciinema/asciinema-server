defmodule Asciinema.SvgRasterTest do
  use ExUnit.Case, async: true
  import Asciinema.PngUtil
  alias Asciinema.SvgRaster

  test "renders PNG with bg runs and mosaic blocks" do
    png =
      SvgRaster.render_png(
        2,
        1,
        {1, 2, 3},
        [{0, 1, 1, {4, 5, 6}}],
        [{0, 0, 0x2580, {7, 8, 9}}]
      )

    assert <<137, 80, 78, 71, 13, 10, 26, 10, _::binary>> = png

    decoded = decode_png(png)

    assert decoded.width == 16
    assert decoded.height == 24
    assert rgb_at(decoded, 0, 0) == {7, 8, 9}
    assert rgb_at(decoded, 0, 23) == {1, 2, 3}
    assert rgb_at(decoded, 8, 12) == {4, 5, 6}
  end

  test "renders box drawing vertical lines with light/heavy widths" do
    png =
      SvgRaster.render_png(
        2,
        1,
        {1, 2, 3},
        [],
        [{0, 0, 0x2502, {240, 16, 32}}, {0, 1, 0x2503, {240, 16, 32}}]
      )

    decoded = decode_png(png)

    # light line: x + 4, width 1
    assert rgb_at(decoded, 4, 12) == {240, 16, 32}
    assert rgb_at(decoded, 3, 12) == {1, 2, 3}

    # heavy line: x + 3, width 2
    assert rgb_at(decoded, 11, 12) == {240, 16, 32}
    assert rgb_at(decoded, 12, 12) == {240, 16, 32}
    assert rgb_at(decoded, 10, 12) == {1, 2, 3}
  end

  test "renders box drawing vertical half-lines with direction and light/heavy widths" do
    png =
      SvgRaster.render_png(
        4,
        1,
        {1, 2, 3},
        [],
        [
          {0, 0, 0x2575, {240, 16, 32}},
          {0, 1, 0x2577, {240, 16, 32}},
          {0, 2, 0x2579, {240, 16, 32}},
          {0, 3, 0x257B, {240, 16, 32}}
        ]
      )

    decoded = decode_png(png)

    # light up (top half only)
    assert rgb_at(decoded, 4, 5) == {240, 16, 32}
    assert rgb_at(decoded, 4, 18) == {1, 2, 3}
    assert rgb_at(decoded, 3, 5) == {1, 2, 3}

    # light down (bottom half only)
    assert rgb_at(decoded, 12, 5) == {1, 2, 3}
    assert rgb_at(decoded, 12, 18) == {240, 16, 32}
    assert rgb_at(decoded, 11, 18) == {1, 2, 3}

    # heavy up (top half only)
    assert rgb_at(decoded, 19, 5) == {240, 16, 32}
    assert rgb_at(decoded, 20, 5) == {240, 16, 32}
    assert rgb_at(decoded, 20, 18) == {1, 2, 3}

    # heavy down (bottom half only)
    assert rgb_at(decoded, 27, 5) == {1, 2, 3}
    assert rgb_at(decoded, 27, 18) == {240, 16, 32}
    assert rgb_at(decoded, 28, 18) == {240, 16, 32}
  end

  test "renders black square as centered half-height mosaic block" do
    png =
      SvgRaster.render_png(
        1,
        1,
        {1, 2, 3},
        [],
        [{0, 0, 0x25A0, {240, 16, 32}}]
      )

    decoded = decode_png(png)

    assert decoded.width == 8
    assert decoded.height == 24
    assert rgb_at(decoded, 0, 0) == {1, 2, 3}
    assert rgb_at(decoded, 0, 6) == {240, 16, 32}
    assert rgb_at(decoded, 7, 17) == {240, 16, 32}
    assert rgb_at(decoded, 7, 23) == {1, 2, 3}
  end

  test "renders sextant symbols with 2x3 cell granularity" do
    png =
      SvgRaster.render_png(
        1,
        1,
        {10, 20, 30},
        [],
        [{0, 0, 0x1FB3B, {200, 100, 50}}]
      )

    decoded = decode_png(png)

    assert decoded.width == 8
    assert decoded.height == 24
    assert rgb_at(decoded, 5, 2) == {200, 100, 50}
    assert rgb_at(decoded, 1, 10) == {200, 100, 50}
    assert rgb_at(decoded, 6, 20) == {200, 100, 50}
    assert rgb_at(decoded, 1, 2) == {10, 20, 30}
  end
end
