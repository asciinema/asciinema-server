defmodule AsciinemaWeb.RecordingSVG do
  use Phoenix.Component
  import AsciinemaWeb.RecordingHTML, only: [term_cols: 1, term_rows: 1]
  import Phoenix.HTML
  alias Asciinema.{Colors, Media, Themes}
  alias Asciinema.SvgRaster
  alias Asciinema.Recordings.Snapshot
  alias AsciinemaWeb.Router.Helpers, as: Routes

  embed_templates "recording_svg/*"

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

  def show(assigns) do
    cols = term_cols(assigns.asciicast)
    rows = term_rows(assigns.asciicast)
    theme = Media.theme(assigns.asciicast)
    coords = coords(assigns.asciicast, nil)

    assigns =
      Map.merge(assigns, %{
        coords: coords,
        cols: cols,
        rows: rows,
        theme: theme,
        image_href: image_href(coords.bg, coords.mosaic_blocks, cols, rows, theme)
      })

    ~H"""
    <.preview
      coords={@coords}
      cols={@cols}
      rows={@rows}
      theme={@theme}
      image_href={@image_href}
      font_family={assigns[:font_family]}
      rx={assigns[:rx]}
      ry={assigns[:ry]}
      logo={true}
      standalone={true}
    />
    """
  end

  def thumbnail_standalone(assigns) do
    ~H"""
    <.thumbnail asciicast={@asciicast} standalone={true} />
    """
  end

  attr :asciicast, :any, required: true
  attr :standalone, :boolean, default: false

  def thumbnail(assigns) do
    cols = 80
    rows = 15
    theme = Media.theme(assigns.asciicast)
    coords = coords(assigns.asciicast, {cols, rows})

    assigns =
      Map.merge(assigns, %{
        coords: coords,
        theme: theme,
        image_href: image_href(coords.bg, coords.mosaic_blocks, cols, rows, theme)
      })

    ~H"""
    <.preview
      coords={@coords}
      cols={80}
      rows={15}
      theme={@theme}
      image_href={@image_href}
      font_family={assigns[:font_family]}
      rx={0}
      ry={0}
      logo={false}
      standalone={@standalone}
    />
    """
  end

  defp coords(asciicast, crop_size) do
    snapshot = snapshot(asciicast, crop_size)
    segments = Snapshot.to_segments(snapshot, split_specials: true)
    fg = fg_coords(segments)

    %{
      bg: bg_coords(segments),
      text: Enum.flat_map(fg, &keep_text/1),
      mosaic_blocks: Enum.flat_map(fg, &keep_mosaic_blocks/1),
      vector_symbols: Enum.flat_map(fg, &keep_vector_symbols/1)
    }
  end

  def fg_coords(lines) do
    lines
    |> Enum.with_index()
    |> Enum.map(&text_line_coords/1)
    |> Enum.filter(&(length(&1.segments) > 0))
  end

  defp text_line_coords({segments, y}) do
    {_, segments} =
      segments
      |> Enum.flat_map(&split_on_whitespace/1)
      |> Enum.reduce({0, []}, fn {text, attrs, char_width}, {x, segments} ->
        width = String.length(text) * char_width

        segments =
          case text do
            " " <> _ -> segments
            _ -> [%{text: text, attrs: attrs, x: x, width: width} | segments]
          end

        {x + width, segments}
      end)

    %{y: y, segments: Enum.reverse(segments)}
  end

  defp split_on_whitespace({text, attrs, 1}) do
    ~r/(^\s+)|\s{2,}/
    |> Regex.split(text, include_captures: true)
    |> Enum.filter(&(String.length(&1) > 0))
    |> Enum.map(&{&1, attrs, 1})
  end

  defp split_on_whitespace(segment), do: [segment]

  def bg_coords(lines) do
    lines
    |> Enum.with_index()
    |> Enum.map(&bg_line_coords/1)
    |> Enum.filter(&(length(&1.segments) > 0))
  end

  defp bg_line_coords({segments, y}) do
    {_, segments} =
      Enum.reduce(segments, {0, []}, fn {text, attrs, char_width}, {x, segments} ->
        width = String.length(text) * char_width

        segments =
          case attrs["bg"] do
            nil -> segments
            _ -> [%{attrs: attrs, x: x, width: width} | segments]
          end

        {x + width, segments}
      end)

    %{y: y, segments: Enum.reverse(segments)}
  end

  defp keep_text(%{y: y, segments: segments}) do
    segments =
      Enum.reject(segments, &(&1.width == 1 && Snapshot.graphic_char?(&1.text)))

    case segments do
      [] -> []
      _ -> [%{y: y, segments: segments}]
    end
  end

  defp keep_mosaic_blocks(%{y: y, segments: segments}) do
    segments =
      Enum.filter(segments, &(&1.width == 1 && mosaic_block?(&1.text)))

    case segments do
      [] -> []
      _ -> [%{y: y, segments: segments}]
    end
  end

  defp keep_vector_symbols(%{y: y, segments: segments}) do
    segments =
      Enum.filter(segments, &(&1.width == 1 && vector_symbol?(&1.text)))

    case segments do
      [] -> []
      _ -> [%{y: y, segments: segments}]
    end
  end

  defp mosaic_block?(char) do
    cp = codepoint(char)

    (cp >= 0x2580 and cp <= 0x259F) || cp == 0x25A0
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

  defp x(x), do: x * @cell_width

  defp y(y), do: y * @font_size * @line_height

  defp w(w), do: w * @cell_width

  defp h(h), do: h * @font_size * @line_height

  defp font_size, do: @font_size

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

  defp snapshot(asciicast, crop_size) do
    (asciicast.snapshot || Snapshot.new([]))
    |> maybe_crop(crop_size)
    |> Snapshot.normalize_colors(asciicast.term_bold_is_bright)
  end

  defp maybe_crop(snapshot, nil), do: snapshot
  defp maybe_crop(snapshot, {cols, rows}), do: Snapshot.crop(snapshot, cols, rows)

  defp codepoint(char) do
    char
    |> String.to_charlist()
    |> Enum.at(0)
  end
end
