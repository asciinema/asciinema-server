defmodule AsciinemaWeb.RecordingSVG do
  use Phoenix.Component
  import Phoenix.HTML
  alias Asciinema.{Colors, Media, Themes}
  alias Asciinema.SvgRaster
  alias Asciinema.Recordings.Snapshot
  alias AsciinemaWeb.Router.Helpers, as: Routes
  alias Phoenix.HTML

  embed_templates "recording_svg/*"

  def render_to_iodata(:thumbnail, asciicast) do
    %{asciicast: asciicast, standalone: true}
    |> thumbnail()
    |> HTML.Safe.to_iodata()
  end

  def render_to_iodata(:full, asciicast) do
    %{asciicast: asciicast}
    |> full()
    |> HTML.Safe.to_iodata()
  end

  def text_extra_attrs(attrs, theme),
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

  def percent(float) do
    "#{Decimal.round(Decimal.from_float(float), 3)}%"
  end

  # Bump when SVG rendering output can change without recording data changes.
  @svg_renderer_salt 4

  def svg_cache_key(asciicast) do
    key =
      if snapshot = asciicast.snapshot do
        Snapshot.seq(snapshot)
      else
        to_string(asciicast.updated_at)
      end <>
        "\u0000" <>
        to_string(asciicast.term_bold_is_bright) <>
        "\u0000" <>
        to_string(asciicast.term_adaptive_palette) <>
        "\u0000" <> Integer.to_string(@svg_renderer_salt)

    :crypto.hash(:sha256, key)
    |> binary_part(0, 12)
    |> Base.url_encode64(padding: false)
  end

  attr :asciicast, :any, required: true
  attr :font_family, :string, default: nil
  attr :rx, :integer, default: nil
  attr :ry, :integer, default: nil

  def full(assigns) do
    ~H"""
    <.preview
      {attrs_for_full(@asciicast)}
      font_family={@font_family}
      rx={@rx}
      ry={@ry}
      standalone={true}
    />
    """
  end

  attr :asciicast, :any, required: true
  attr :standalone, :boolean, default: false

  def thumbnail(assigns) do
    ~H"""
    <.preview {attrs_for_thumbnail(@asciicast)} rx={0} ry={0} standalone={@standalone} />
    """
  end

  attr :cols, :integer, required: true
  attr :rows, :integer, required: true
  attr :coords, :any, required: true
  attr :theme, :any, required: true
  attr :image_href, :string, required: true
  attr :standalone, :boolean, required: true
  attr :logo, :any, default: nil
  attr :font_family, :string, default: nil
  attr :rx, :integer, default: nil
  attr :ry, :integer, default: nil

  def preview(assigns)

  defp term_cols(asciicast), do: asciicast.term_cols_override || asciicast.term_cols

  defp term_rows(asciicast), do: asciicast.term_rows_override || asciicast.term_rows

  defp attrs_for_full(asciicast) do
    cols = term_cols(asciicast)
    rows = term_rows(asciicast)
    theme = svg_theme(asciicast)
    coords = coords(asciicast, nil, theme)

    %{
      cols: cols,
      rows: rows,
      coords: coords,
      theme: theme,
      image_href: image_href(coords.bg, coords.mosaic_blocks, cols, rows, theme),
      logo: logo_overlay(cols, rows)
    }
  end

  defp attrs_for_thumbnail(asciicast) do
    cols = 80
    rows = 15
    theme = svg_theme(asciicast)
    coords = coords(asciicast, {cols, rows}, theme)

    %{
      cols: cols,
      rows: rows,
      coords: coords,
      theme: theme,
      image_href: image_href(coords.bg, coords.mosaic_blocks, cols, rows, theme),
      logo: nil
    }
  end

  defp coords(asciicast, crop_size, theme) do
    asciicast
    |> snapshot(crop_size, theme)
    |> coords_from_snapshot()
  end

  defp coords_from_snapshot(snapshot) do
    {bg, text, mosaic_blocks, vector_symbols} =
      snapshot
      |> Enum.with_index()
      |> Enum.reduce({[], [], [], []}, fn {line, y}, {bg, text, mosaic_blocks, vector_symbols} ->
        {line_bg, line_text, line_mosaic, line_vector} = line_coords(line)

        {
          prepend_line(bg, y, Enum.reverse(line_bg)),
          prepend_line(text, y, Enum.reverse(line_text)),
          prepend_line(mosaic_blocks, y, Enum.reverse(line_mosaic)),
          prepend_line(vector_symbols, y, Enum.reverse(line_vector))
        }
      end)

    %{
      bg: Enum.reverse(bg),
      text: Enum.reverse(text),
      mosaic_blocks: Enum.reverse(mosaic_blocks),
      vector_symbols: Enum.reverse(vector_symbols)
    }
  end

  defp line_coords(line) do
    {state, pending} =
      Enum.reduce(
        line,
        {{[], [], [], []}, nil},
        fn {x, cp, attrs, char_width}, {state, pending} ->
          char = <<cp::utf8>>

          cond do
            positioning_split?(cp, char_width) ->
              state =
                pending
                |> flush_coords_segment(state)
                |> add_coords_segment(x, char, attrs, char_width)

              {state, nil}

            pending == nil ->
              {state, {x, [char], attrs, char_width}}

            same_segment?(pending, attrs, char_width) ->
              {state, append_char(pending, char)}

            true ->
              {flush_coords_segment(pending, state), {x, [char], attrs, char_width}}
          end
        end
      )

    flush_coords_segment(pending, state)
  end

  defp same_segment?({_x, _chars, attrs, char_width}, attrs, char_width), do: true
  defp same_segment?(_pending, _attrs, _char_width), do: false

  defp append_char({x, chars, attrs, char_width}, char),
    do: {x, [char | chars], attrs, char_width}

  defp flush_coords_segment(nil, state), do: state

  defp flush_coords_segment({x, chars, attrs, char_width}, state) do
    add_coords_segment(state, x, chars_to_text(chars), attrs, char_width)
  end

  defp chars_to_text(chars) do
    chars
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  defp add_coords_segment({bg, text, mosaics, vectors}, x, segment_text, attrs, char_width) do
    width = String.length(segment_text) * char_width

    bg =
      case attrs["bg"] do
        nil -> bg
        _ -> [%{attrs: attrs, x: x, width: width} | bg]
      end

    {text, mosaics, vectors} =
      emit_fg_segments(segment_text, attrs, char_width, x, {text, mosaics, vectors})

    {bg, text, mosaics, vectors}
  end

  defp emit_fg_segments(segment_text, attrs, char_width, x, {text, mosaics, vectors}) do
    segment = %{
      text: segment_text,
      attrs: attrs,
      x: x,
      width: String.length(segment_text) * char_width
    }

    {text, mosaics, vectors} =
      cond do
        mosaic_block?(segment_text) ->
          {text, [segment | mosaics], vectors}

        vector_symbol?(segment_text) ->
          {text, mosaics, [segment | vectors]}

        true ->
          {[segment | text], mosaics, vectors}
      end

    {text, mosaics, vectors}
  end

  defp prepend_line(lines, _y, []), do: lines
  defp prepend_line(lines, y, segments), do: [%{y: y, segments: segments} | lines]

  @box_drawing_first 0x2500
  @box_drawing_last 0x257F
  @block_elements_first 0x2580
  @block_elements_last 0x259F
  @black_square 0x25A0
  @black_large_circle 0x2B24
  @sextants_first 0x1FB00
  @sextants_last 0x1FB3B
  @braille_patterns_first 0x2800
  @braille_patterns_last 0x28FF
  @powerline_triangles_first 0xE0B0
  @powerline_triangles_last 0xE0B3

  defp positioning_split?(cp, char_width) do
    char_width > 1 ||
      (cp >= @box_drawing_first and cp <= @box_drawing_last) ||
      (cp >= @block_elements_first and cp <= @block_elements_last) ||
      cp == @black_square ||
      cp == @black_large_circle ||
      (cp >= @sextants_first and cp <= @sextants_last) ||
      (cp >= @braille_patterns_first and cp <= @braille_patterns_last) ||
      (cp >= @powerline_triangles_first and cp <= @powerline_triangles_last)
  end

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

  defp vector_symbol?(char) do
    cp = codepoint(char)

    # powerline triangles
    cp >= 0xE0B0 and cp <= 0xE0B3
  end

  def vector_symbol(assigns) do
    case codepoint(assigns.char) do
      # powerline right full triangle
      0xE0B0 ->
        ~H"""
        <polygon
          points={"#{x(@x)} #{y(@y)}, #{x(@x + 1)} #{y(@y + 0.5)}, #{x(@x)} #{y(@y + 1)}"}
          fill={fg_color(@attrs, @theme, true)}
        />
        """

      # powerline right outline triangle
      0xE0B1 ->
        ~H"""
        <polyline
          points={"#{x(@x)} #{y(@y)}, #{x(@x + 1)} #{y(@y + 0.5)}, #{x(@x)} #{y(@y + 1)}"}
          fill="none"
          stroke={fg_color(@attrs, @theme, true)}
        />
        """

      # powerline left full triangle
      0xE0B2 ->
        ~H"""
        <polygon
          points={"#{x(@x + 1)} #{y(@y)}, #{x(@x)} #{y(@y + 0.5)}, #{x(@x + 1)} #{y(@y + 1)}"}
          fill={fg_color(@attrs, @theme, true)}
        />
        """

      # powerline left outline triangle
      0xE0B3 ->
        ~H"""
        <polyline
          points={"#{x(@x + 1)} #{y(@y)}, #{x(@x)} #{y(@y + 0.5)}, #{x(@x + 1)} #{y(@y + 1)}"}
          fill="none"
          stroke={fg_color(@attrs, @theme, true)}
        />
        """
    end
  end

  @font_size 14
  @line_height 1.333333
  @cell_width 8.42333333
  @logo_scale 0.2

  defp x(x), do: x * @cell_width

  defp y(y), do: y * @font_size * @line_height

  defp w(w), do: w * @cell_width

  defp h(h), do: h * @font_size * @line_height

  defp font_size, do: @font_size

  defp logo_overlay(cols, rows) do
    svg_width = w(cols + 2)
    svg_height = h(rows + 1)

    size =
      svg_width
      |> min(svg_height)
      |> Kernel.*(@logo_scale)
      |> round_float()

    %{
      x: round_float((svg_width - size) / 2),
      y: round_float((svg_height - size) / 2),
      size: size
    }
  end

  defp round_float(value), do: Float.round(value, 3)

  defp image_href(bg_coords, mosaic_block_coords, cols, rows, theme) do
    default_bg = Colors.parse(theme.bg)

    bg_runs =
      for %{y: y, segments: segments} <- bg_coords,
          %{x: x, width: width, attrs: attrs} <- segments do
        {y, x, width, bg_color_tuple(attrs, theme)}
      end

    mosaic_blocks =
      for %{y: y, segments: segments} <- mosaic_block_coords,
          %{x: x, text: char, attrs: attrs} <- segments do
        {y, x, codepoint(char), mosaic_block_color_tuple(char, attrs, theme)}
      end

    png = SvgRaster.render_png(cols, rows, default_bg, bg_runs, mosaic_blocks)

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

  defp snapshot(asciicast, crop_size, theme) do
    (asciicast.snapshot || Snapshot.new([]))
    |> maybe_crop(crop_size)
    |> Snapshot.normalize_colors(asciicast.term_bold_is_bright, theme)
  end

  defp svg_theme(asciicast) do
    asciicast
    |> Media.theme()
    |> Themes.with_256_palette(asciicast.term_adaptive_palette || false)
  end

  defp maybe_crop(snapshot, nil), do: snapshot
  defp maybe_crop(snapshot, {cols, rows}), do: Snapshot.crop(snapshot, cols, rows)

  defp codepoint(<<cp::utf8, _::binary>>), do: cp
end
