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
    assert decoded.height == 8
    assert rgb_at(decoded, 0, 0) == {7, 8, 9}
    assert rgb_at(decoded, 0, 7) == {1, 2, 3}
    assert rgb_at(decoded, 8, 4) == {4, 5, 6}
  end
end
