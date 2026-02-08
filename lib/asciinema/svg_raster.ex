defmodule Asciinema.SvgRaster do
  use Rustler, otp_app: :asciinema, crate: :svg_raster

  @type rgb8 :: {0..255, 0..255, 0..255}
  @type bg_run :: {non_neg_integer, non_neg_integer, non_neg_integer, rgb8}
  @type mosaic_block :: {non_neg_integer, non_neg_integer, non_neg_integer, rgb8}

  @spec render_png(pos_integer, pos_integer, rgb8, [bg_run], [mosaic_block]) :: binary
  def render_png(_cols, _rows, _default_bg, _bg_runs, _mosaic_blocks),
    do: :erlang.nif_error(:nif_not_loaded)
end
