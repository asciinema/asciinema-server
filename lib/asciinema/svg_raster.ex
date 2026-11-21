defmodule Asciinema.SvgRaster do
  use Rustler, otp_app: :asciinema, crate: :svg_raster

  @type rgb8 :: {0..255, 0..255, 0..255}
  @type bg_run :: {non_neg_integer, non_neg_integer, non_neg_integer, rgb8}
  @type mosaic_block :: {non_neg_integer, non_neg_integer, non_neg_integer, rgb8}

  @typedoc "Whether the top and bottom grid rows contain padding-blocking Powerline symbols."
  @type powerline_edges :: {boolean, boolean}

  @type cursor_overlay ::
          {non_neg_integer, non_neg_integer, pos_integer, rgb8, {non_neg_integer, rgb8} | nil}

  @spec render_png(
          pos_integer,
          pos_integer,
          rgb8,
          [bg_run],
          [mosaic_block],
          cursor_overlay | nil,
          powerline_edges
        ) :: binary
  def render_png(
        _cols,
        _rows,
        _default_bg,
        _bg_runs,
        _mosaic_blocks,
        _cursor_overlay \\ nil,
        _powerline_edges \\ {false, false}
      ),
      do: :erlang.nif_error(:nif_not_loaded)
end
