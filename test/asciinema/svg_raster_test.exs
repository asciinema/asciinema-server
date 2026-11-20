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

    assert decoded.width == 32
    assert decoded.height == 48
    assert grid_rgb_at(decoded, 0, 0) == {7, 8, 9}
    assert grid_rgb_at(decoded, 0, 23) == {1, 2, 3}
    assert grid_rgb_at(decoded, 8, 12) == {4, 5, 6}
  end

  test "renders representative glyphs supported by rasterized groups" do
    fg = {240, 16, 32}
    bg = {1, 2, 3}

    # 0: █, 1: ┃, 2: ╹, 3: ╻, 4: ■, 5: 🬀
    mosaic_blocks = [
      {0, 0, 0x2588, fg},
      {0, 1, 0x2503, fg},
      {0, 2, 0x2579, fg},
      {0, 3, 0x257B, fg},
      {0, 4, 0x25A0, fg},
      {0, 5, 0x1FB00, fg}
    ]

    png = SvgRaster.render_png(6, 1, bg, [], mosaic_blocks)
    decoded = decode_png(png)

    # block elements
    assert cell_contains_color?(decoded, 0, 0, fg)

    # heavy box verticals
    assert cell_contains_color?(decoded, 1, 0, fg)
    assert cell_contains_color?(decoded, 2, 0, fg)
    assert cell_contains_color?(decoded, 3, 0, fg)

    # black square
    assert cell_contains_color?(decoded, 4, 0, fg)

    # sextants
    assert cell_contains_color?(decoded, 5, 0, fg)
  end

  test "renders heavy box drawing vertical lines on raster layer" do
    png =
      SvgRaster.render_png(
        2,
        1,
        {1, 2, 3},
        [],
        [{0, 0, 0x2502, {240, 16, 32}}, {0, 1, 0x2503, {240, 16, 32}}]
      )

    decoded = decode_png(png)

    # heavy line: x + 3, width 2
    assert grid_rgb_at(decoded, 11, 12) == {240, 16, 32}
    assert grid_rgb_at(decoded, 12, 12) == {240, 16, 32}
    assert grid_rgb_at(decoded, 10, 12) == {1, 2, 3}
  end

  test "renders heavy box drawing vertical half-lines on raster layer" do
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

    # heavy up (top half only)
    assert grid_rgb_at(decoded, 19, 5) == {240, 16, 32}
    assert grid_rgb_at(decoded, 20, 5) == {240, 16, 32}
    assert grid_rgb_at(decoded, 20, 18) == {1, 2, 3}

    # heavy down (bottom half only)
    assert grid_rgb_at(decoded, 27, 5) == {1, 2, 3}
    assert grid_rgb_at(decoded, 27, 18) == {240, 16, 32}
    assert grid_rgb_at(decoded, 28, 18) == {240, 16, 32}
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

    assert decoded.width == 24
    assert decoded.height == 48
    assert grid_rgb_at(decoded, 0, 0) == {1, 2, 3}
    assert grid_rgb_at(decoded, 0, 6) == {240, 16, 32}
    assert grid_rgb_at(decoded, 7, 17) == {240, 16, 32}
    assert grid_rgb_at(decoded, 7, 23) == {1, 2, 3}
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

    assert decoded.width == 24
    assert decoded.height == 48
    assert grid_rgb_at(decoded, 5, 2) == {200, 100, 50}
    assert grid_rgb_at(decoded, 1, 10) == {200, 100, 50}
    assert grid_rgb_at(decoded, 6, 20) == {200, 100, 50}
    assert grid_rgb_at(decoded, 1, 2) == {10, 20, 30}
  end

  test "extends neighboring backgrounds across all padding and corners" do
    colors = for i <- 1..9, do: {i, i * 2, i * 3}

    runs =
      for {color, i} <- Enum.with_index(colors),
          do: {div(i, 3), rem(i, 3), 1, color}

    png = SvgRaster.render_png(3, 3, {0, 0, 0}, runs, []) |> decode_png()

    for y <- 0..(png.height - 1), x <- 0..(png.width - 1) do
      col = div(max(x - 8, 0), 8) |> min(2)
      row = div(max(y - 12, 0), 24) |> min(2)
      assert rgb_at(png, x, y) == Enum.at(colors, row * 3 + col)
    end
  end

  test "extends full blocks but only the backgrounds of partial blocks" do
    bg = {1, 2, 3}
    fg = {4, 5, 6}
    full = SvgRaster.render_png(1, 1, bg, [], [{0, 0, 0x2588, fg}]) |> decode_png()
    half = SvgRaster.render_png(1, 1, bg, [], [{0, 0, 0x2580, fg}]) |> decode_png()

    for y <- 0..47, x <- 0..23 do
      assert rgb_at(full, x, y) == fg

      expected = if x in 8..15 and y in 12..23, do: fg, else: bg
      assert rgb_at(half, x, y) == expected
    end
  end

  test "clips runs before extension and fills missing cells with default background" do
    bg = {1, 2, 3}
    fg = {4, 5, 6}
    runs = [{0, 1, 100, fg}, {0, 3, 1, fg}, {1, 0, 0, fg}, {2, 0, 3, fg}]
    png = SvgRaster.render_png(3, 2, bg, runs, []) |> decode_png()

    assert rgb_at(png, 0, 0) == bg
    assert rgb_at(png, 39, 0) == fg
    assert rgb_at(png, 39, 35) == fg
    assert rgb_at(png, 39, 36) == bg
    assert rgb_at(png, 0, 71) == bg
    assert rgb_at(png, 39, 71) == bg
  end

  test "draws cursor overlays at each corner without changing padding" do
    bg = {1, 2, 3}
    cursor = {4, 5, 6}

    for {x, y} <- [{0, 0}, {2, 0}, {0, 2}, {2, 2}] do
      png =
        SvgRaster.render_png(3, 3, bg, [], [], {y, x, 1, cursor, nil})
        |> decode_png()

      assert grid_rgb_at(png, x * 8, y * 24) == cursor

      for px <- 0..(png.width - 1) do
        assert rgb_at(png, px, 0) == bg
        assert rgb_at(png, px, png.height - 1) == bg
      end

      for py <- 0..(png.height - 1) do
        assert rgb_at(png, 0, py) == bg
        assert rgb_at(png, png.width - 1, py) == bg
      end
    end
  end
end
