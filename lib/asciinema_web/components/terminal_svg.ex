defmodule AsciinemaWeb.TerminalSVG do
  @moduledoc "SVG rendering of terminal snapshots, independent of their recording or stream source."

  use Phoenix.Component
  import Phoenix.HTML
  alias Asciinema.{Colors, Themes}
  alias Asciinema.Recordings.Snapshot
  alias Asciinema.SvgRaster

  use AsciinemaWeb, :verified_routes

  embed_templates "terminal_svg/*", private: true

  defp text_extra_attrs(attrs, theme),
    do: %{style: text_style(attrs, theme), class: text_class(attrs)}

  defp text_style(attrs, theme) do
    case fg_color(attrs, theme) do
      nil -> nil
      color -> "fill: #{color}"
    end
  end

  defp text_class(%{} = attrs) do
    classes =
      attrs
      |> Enum.map(&text_class/1)
      |> Enum.filter(& &1)
      |> Enum.uniq()

    case classes do
      [] -> nil
      _ -> Enum.join(classes, " ")
    end
  end

  defp text_class({"bold", true}), do: "br"
  defp text_class({"faint", true}), do: "fa"
  defp text_class({"italic", true}), do: "it"
  defp text_class({"underline", true}), do: "un"
  defp text_class(_), do: nil

  defp bg_color(%{"bg" => bg}, theme) when is_integer(bg), do: Themes.color(theme, bg)
  defp bg_color(%{"bg" => "#" <> _ = c}, _theme), do: c
  defp bg_color(%{"bg" => [_r, _g, _b] = c}, _theme), do: Colors.hex(c)
  defp bg_color(%{"bg" => "rgb(" <> _ = c}, _theme), do: c
  defp bg_color(_, theme), do: theme.bg

  defp fg_color(attrs, theme, default_fallback \\ false)
  defp fg_color(%{"fg" => fg}, theme, _) when is_integer(fg), do: Themes.color(theme, fg)
  defp fg_color(%{"fg" => "#" <> _ = c}, _theme, _), do: c
  defp fg_color(%{"fg" => [_r, _g, _b] = c}, _theme, _), do: Colors.hex(c)
  defp fg_color(%{"fg" => "rgb(" <> _ = c}, _theme, _), do: c
  defp fg_color(_, _, false), do: nil
  defp fg_color(_, theme, true), do: theme.fg

  @doc """
  Renders a snapshot at explicit terminal dimensions.

  The theme is a resolved theme map. A nil snapshot renders an empty terminal.
  The optional overlay receives the padded viewport's pixel width and height.
  """
  attr :snapshot, :any, required: true
  attr :theme, :map, required: true
  attr :cols, :integer, required: true
  attr :rows, :integer, required: true
  attr :bold_is_bright, :boolean, default: false
  attr :adaptive_palette, :boolean, default: false
  attr :standalone, :boolean, default: false
  attr :font_family, :string, default: nil
  attr :rx, :integer, default: nil
  attr :ry, :integer, default: nil
  slot :overlay

  def preview(assigns) do
    assigns
    |> assign(:responsive, false)
    |> render_snapshot()
  end

  @thumbnail_cols 70
  @thumbnail_rows 15

  @doc "Renders a responsive #{@thumbnail_cols}x#{@thumbnail_rows} thumbnail, cropping before color normalization."
  attr :snapshot, :any, required: true
  attr :theme, :map, required: true
  attr :bold_is_bright, :boolean, default: false
  attr :adaptive_palette, :boolean, default: false
  attr :standalone, :boolean, default: false

  def thumbnail(assigns) do
    snapshot =
      (assigns.snapshot || Snapshot.from_segments([]))
      |> Snapshot.crop_for_thumbnail(@thumbnail_cols, @thumbnail_rows)

    assigns
    |> assign(
      snapshot: snapshot,
      cols: @thumbnail_cols,
      rows: @thumbnail_rows,
      rx: 0,
      ry: 0,
      font_family: nil,
      overlay: [],
      responsive: true
    )
    |> render_snapshot()
  end

  defp render_snapshot(assigns) do
    theme = Themes.with_256_palette(assigns.theme, assigns.adaptive_palette || false)

    snapshot =
      (assigns.snapshot || Snapshot.from_segments([]))
      |> Snapshot.normalize_colors(assigns.bold_is_bright, theme)

    coords = coords_from_snapshot(snapshot, theme, {assigns.cols, assigns.rows})

    assigns
    |> assign(
      coords: coords,
      theme: theme,
      image_href: image_href(coords, assigns.cols, assigns.rows, theme),
      viewport: %{width: w(assigns.cols + 2), height: h(assigns.rows + 1)}
    )
    |> terminal()
  end

  defp coords_from_snapshot(snapshot, theme, {cols, rows}) do
    cursor =
      case snapshot.cursor do
        {x, y} when x >= 0 and x < cols and y >= 0 and y < rows -> {x, y}
        _ -> nil
      end

    {{bg, text, mosaic_blocks, vector_symbols}, cursor_overlay} =
      snapshot
      |> Enum.with_index()
      |> Enum.reduce({{[], [], [], []}, nil}, fn {line, y},
                                                 {{bg, text, mosaic_blocks, vector_symbols},
                                                  cursor_overlay} ->
        cursor_x =
          case cursor do
            {x, ^y} -> x
            _ -> nil
          end

        {{line_bg, line_text, line_mosaic, line_vector}, line_cursor_overlay} =
          line_coords(line, y, cursor_x, theme)

        cursor_overlay =
          case line_cursor_overlay do
            {x, width, color, mosaic} -> {y, x, width, color, mosaic}
            nil -> cursor_overlay
          end

        {
          {
            line_bg ++ bg,
            prepend_line(text, y, Enum.reverse(line_text)),
            line_mosaic ++ mosaic_blocks,
            prepend_line(vector_symbols, y, Enum.reverse(line_vector))
          },
          cursor_overlay
        }
      end)

    cursor_overlay =
      case {cursor, cursor_overlay} do
        {{x, y}, nil} ->
          {y, x, 1, Colors.parse(theme.fg), nil}

        _ ->
          cursor_overlay
      end

    %{
      bg_runs: Enum.reverse(bg),
      text: Enum.reverse(text),
      mosaic_blocks: Enum.reverse(mosaic_blocks),
      vector_symbols: Enum.reverse(vector_symbols),
      cursor_overlay: cursor_overlay,
      powerline_edges: {
        row_has_padding_powerline?(Enum.at(snapshot, 0, []), cols),
        row_has_padding_powerline?(Enum.at(snapshot, rows - 1, []), cols)
      }
    }
  end

  defp row_has_padding_powerline?(line, cols) do
    Enum.any?(line, fn {x, cp, _attrs, _width} ->
      x < cols && padding_powerline_symbol?(cp)
    end)
  end

  defp padding_powerline_symbol?(cp) do
    cp in 0xE0B0..0xE0C8 or cp == 0xE0CA or cp in 0xE0CC..0xE0D2 or cp == 0xE0D4
  end

  defp line_coords(line, y, cursor_x, theme) do
    {state, pending, cursor_overlay} =
      Enum.reduce(
        line,
        {{[], [], [], []}, nil, nil},
        fn {x, cp, attrs, char_width}, {state, pending, cursor_overlay} ->
          char = <<cp::utf8>>
          cursor_here? = is_integer(cursor_x) and cursor_x >= x and cursor_x < x + char_width

          {fg_attrs, cursor_overlay} =
            if cursor_here? do
              cursor_attrs =
                Map.merge(attrs, %{
                  "fg" => bg_color(attrs, theme),
                  "bg" => fg_color(attrs, theme, true)
                })

              mosaic =
                if mosaic_block?(char),
                  do: {cp, mosaic_block_color_tuple(char, cursor_attrs, theme)}

              {cursor_attrs, {x, char_width, bg_color_tuple(cursor_attrs, theme), mosaic}}
            else
              {attrs, cursor_overlay}
            end

          {state, pending} =
            cond do
              cursor_here? or positioning_split?(cp, char_width) ->
                state =
                  pending
                  |> flush_coords_segment(state, y, theme)
                  |> add_coords_segment({x, char, attrs, char_width}, y, theme, fg_attrs)

                {state, nil}

              pending == nil ->
                {state, {x, [char], attrs, char_width}}

              same_segment?(pending, attrs, char_width) ->
                {state, append_char(pending, char)}

              true ->
                {flush_coords_segment(pending, state, y, theme), {x, [char], attrs, char_width}}
            end

          {state, pending, cursor_overlay}
        end
      )

    {flush_coords_segment(pending, state, y, theme), cursor_overlay}
  end

  defp same_segment?({_x, _chars, attrs, char_width}, attrs, char_width), do: true
  defp same_segment?(_pending, _attrs, _char_width), do: false

  defp append_char({x, chars, attrs, char_width}, char),
    do: {x, [char | chars], attrs, char_width}

  defp flush_coords_segment(nil, state, _y, _theme), do: state

  defp flush_coords_segment({x, chars, attrs, char_width}, state, y, theme) do
    add_coords_segment(state, {x, chars_to_text(chars), attrs, char_width}, y, theme)
  end

  defp chars_to_text(chars) do
    chars
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  defp add_coords_segment(
         {bg, text, mosaics, vectors},
         {x, segment_text, attrs, char_width},
         y,
         theme,
         fg_attrs \\ nil
       ) do
    bg =
      case attrs["bg"] do
        nil ->
          bg

        _ ->
          width = String.length(segment_text) * char_width
          [{y, x, width, bg_color_tuple(attrs, theme)} | bg]
      end

    if mosaic_block?(segment_text) do
      # Raster content stays cursor-free; its cursor styling is drawn by the overlay.
      mosaic =
        {y, x, codepoint(segment_text), mosaic_block_color_tuple(segment_text, attrs, theme)}

      {bg, text, [mosaic | mosaics], vectors}
    else
      segment = %{text: segment_text, attrs: fg_attrs || attrs, x: x}

      if vector_symbol?(segment_text) do
        {bg, text, mosaics, [segment | vectors]}
      else
        {bg, [segment | text], mosaics, vectors}
      end
    end
  end

  defp prepend_line(lines, _y, []), do: lines
  defp prepend_line(lines, y, segments), do: [%{y: y, segments: segments} | lines]

  @box_drawing_first 0x2500
  @box_drawing_last 0x257F
  @block_elements_first 0x2580
  @block_elements_last 0x259F
  @black_square 0x25A0
  @black_large_circle 0x2B24
  @sextile 0x26B9
  @sextants_first 0x1FB00
  @sextants_last 0x1FB3B
  @braille_patterns_first 0x2800
  @braille_patterns_last 0x28FF
  @powerline_first 0xE0B0
  @powerline_last 0xE0BF
  @powerline_nudge 0.02
  @powerline_stroke_width 0.07

  defp positioning_split?(cp, char_width) do
    char_width > 1 ||
      (cp >= @box_drawing_first and cp <= @box_drawing_last) ||
      (cp >= @block_elements_first and cp <= @block_elements_last) ||
      cp == @black_square ||
      cp == @black_large_circle ||
      cp == @sextile ||
      (cp >= @sextants_first and cp <= @sextants_last) ||
      (cp >= @braille_patterns_first and cp <= @braille_patterns_last) ||
      powerline_symbol?(cp)
  end

  defp powerline_symbol?(cp), do: cp >= @powerline_first and cp <= @powerline_last

  defp mosaic_block?(char) do
    cp = codepoint(char)

    # block elements || heavy box drawing verticals || black square || sextants
    (cp >= 0x2580 and cp <= 0x259F) ||
      cp == 0x2503 ||
      cp == 0x2579 ||
      cp == 0x257B ||
      cp == 0x25A0 ||
      (cp >= 0x1FB00 and cp <= 0x1FB3B)
  end

  defp vector_symbol?(char), do: powerline_symbol?(codepoint(char))

  defp vector_symbol(assigns) do
    assigns =
      assign(assigns,
        path: powerline_path(codepoint(assigns.char)),
        color: fg_color(assigns.attrs, assigns.theme, true),
        nudge: @powerline_nudge,
        stroke_width: @powerline_stroke_width
      )

    ~H"""
    <svg
      x={x(@x - @nudge)}
      y={y(@y)}
      width={w(1 + @nudge * 2)}
      height={h(1)}
      viewBox="0 0 1 1"
      preserveAspectRatio="none"
      overflow="visible"
    >
      <path
        d={@path.d}
        fill={if @path[:fill], do: @color, else: "none"}
        stroke={if @path[:stroke], do: @color}
        stroke-width={if @path[:stroke], do: @stroke_width}
        stroke-linejoin={@path[:stroke_linejoin]}
      />
    </svg>
    """
  end

  defp powerline_path(0xE0B0), do: %{d: "M0,0 L1,0.5 L0,1 Z", fill: true}

  defp powerline_path(0xE0B1),
    do: %{d: "M0,0 L1,0.5 L0,1", stroke: true, stroke_linejoin: "miter"}

  defp powerline_path(0xE0B2), do: %{d: "M1,0 L0,0.5 L1,1 Z", fill: true}

  defp powerline_path(0xE0B3),
    do: %{d: "M1,0 L0,0.5 L1,1", stroke: true, stroke_linejoin: "miter"}

  defp powerline_path(0xE0B4), do: %{d: "M0,0 A1,0.5 0 0 1 0,1 Z", fill: true}
  defp powerline_path(0xE0B5), do: %{d: "M0,0 A1,0.5 0 0 1 0,1", stroke: true}
  defp powerline_path(0xE0B6), do: %{d: "M1,0 A1,0.5 0 0 0 1,1 Z", fill: true}
  defp powerline_path(0xE0B7), do: %{d: "M1,0 A1,0.5 0 0 0 1,1", stroke: true}
  defp powerline_path(0xE0B8), do: %{d: "M0,1 L0,0 L1,1 Z", fill: true}
  defp powerline_path(0xE0B9), do: %{d: "M0,0 L1,1", stroke: true}
  defp powerline_path(0xE0BA), do: %{d: "M1,1 L1,0 L0,1 Z", fill: true}
  defp powerline_path(0xE0BB), do: %{d: "M0,1 L1,0", stroke: true}
  defp powerline_path(0xE0BC), do: %{d: "M0,0 L1,0 L0,1 Z", fill: true}
  defp powerline_path(0xE0BD), do: %{d: "M0,1 L1,0", stroke: true}
  defp powerline_path(0xE0BE), do: %{d: "M1,0 L1,1 L0,0 Z", fill: true}
  defp powerline_path(0xE0BF), do: %{d: "M0,0 L1,1", stroke: true}

  @font_size 14
  @line_height 1.333333
  @cell_width 8.42333333

  defp x(x), do: x * @cell_width

  defp y(y), do: y * @font_size * @line_height

  defp w(w), do: w * @cell_width

  defp h(h), do: h * @font_size * @line_height

  defp font_size, do: @font_size

  defp image_href(coords, cols, rows, theme) do
    png =
      SvgRaster.render_png(
        cols,
        rows,
        Colors.parse(theme.bg),
        coords.bg_runs,
        coords.mosaic_blocks,
        coords.cursor_overlay,
        coords.powerline_edges
      )

    "data:image/png;base64," <> Base.encode64(png)
  end

  defp bg_color_tuple(attrs, theme) do
    attrs
    |> bg_color(theme)
    |> Colors.parse()
  end

  defp mosaic_block_color_tuple(char, attrs, theme) do
    color =
      case codepoint(char) do
        0x2591 -> Colors.mix(fg_color(attrs, theme, true), bg_color(attrs, theme), 0.25)
        0x2592 -> Colors.mix(fg_color(attrs, theme, true), bg_color(attrs, theme), 0.5)
        0x2593 -> Colors.mix(fg_color(attrs, theme, true), bg_color(attrs, theme), 0.75)
        _ -> fg_color(attrs, theme, true)
      end

    Colors.parse(color)
  end

  defp codepoint(<<cp::utf8, _::binary>>), do: cp
end
