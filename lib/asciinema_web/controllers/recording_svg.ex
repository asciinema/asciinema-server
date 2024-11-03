defmodule AsciinemaWeb.RecordingSVG do
  use Phoenix.Component
  import AsciinemaWeb.RecordingHTML, only: [cols: 1, rows: 1]
  import Phoenix.HTML
  alias Asciinema.{Colors, Media, Themes}
  alias Asciinema.Recordings.Snapshot

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

  defp bg_style(attrs, theme) do
    case bg_color(attrs, theme) do
      nil -> nil
      color -> "fill: #{color}"
    end
  end

  defp bg_color(attrs, theme, default_fallback \\ false)
  defp bg_color(%{"bg" => bg}, theme, _) when is_integer(bg), do: Themes.color(theme, bg)
  defp bg_color(%{"bg" => "#" <> _ = c}, _theme, _), do: c
  defp bg_color(%{"bg" => [_r, _g, _b] = c}, _theme, _), do: Colors.hex(c)
  defp bg_color(%{"bg" => "rgb(" <> _ = c}, _theme, _), do: c
  defp bg_color(_, _, false), do: nil
  defp bg_color(_, theme, true), do: theme.bg

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
    ~H"""
    <%= raw("<?xml version=\"1.0\"?>") %>
    <.preview
      coords={coords(@asciicast, nil)}
      cols={cols(@asciicast)}
      rows={rows(@asciicast)}
      theme={Media.theme(@asciicast)}
      font_family={assigns[:font_family]}
      rx={assigns[:rx]}
      ry={assigns[:ry]}
      logo={true}
    />
    """
  end

  def thumbnail(assigns) do
    ~H"""
    <%= raw("<?xml version=\"1.0\"?>") %>
    <.preview
      coords={coords(@asciicast, {80, 15})}
      cols={80}
      rows={15}
      theme={Media.theme(@asciicast)}
      font_family={assigns[:font_family]}
      rx={0}
      ry={0}
      logo={false}
    />
    """
  end

  defp coords(asciicast, crop_size) do
    snapshot = snapshot(asciicast, crop_size)
    fg = Snapshot.fg_coords(snapshot)

    %{
      bg: Snapshot.bg_coords(snapshot),
      text: Enum.flat_map(fg, &keep_text/1),
      special_chars: Enum.flat_map(fg, &keep_special_chars/1)
    }
  end

  defp keep_text(%{y: y, segments: segments}) do
    segments =
      Enum.reject(segments, &(&1.width == 1 && Snapshot.block_or_powerline_triangle?(&1.text)))

    case segments do
      [] -> []
      _ -> [%{y: y, segments: segments}]
    end
  end

  defp keep_special_chars(%{y: y, segments: segments}) do
    segments =
      Enum.filter(segments, &(&1.width == 1 && Snapshot.block_or_powerline_triangle?(&1.text)))

    case segments do
      [] -> []
      _ -> [%{y: y, segments: segments}]
    end
  end

  def special_char(assigns) do
    case Enum.at(String.to_charlist(assigns.char), 0) do
      # upper half block
      0x2580 ->
        ~H"""
        <rect x={x(@x)} y={y(@y)} width={w(1)} height={h(0.5)} style={fg(@attrs, @theme)} />
        """

      # lower one eighth block
      0x2581 ->
        ~H"""
        <rect x={x(@x)} y={y(@y + 7 / 8)} width={w(1)} height={h(1 / 8)} style={fg(@attrs, @theme)} />
        """

      # lower one quarter block
      0x2582 ->
        ~H"""
        <rect x={x(@x)} y={y(@y + 3 / 4)} width={w(1)} height={h(1 / 4)} style={fg(@attrs, @theme)} />
        """

      # lower three eighths block
      0x2583 ->
        ~H"""
        <rect x={x(@x)} y={y(@y + 5 / 8)} width={w(1)} height={h(3 / 8)} style={fg(@attrs, @theme)} />
        """

      # lower half block
      0x2584 ->
        ~H"""
        <rect x={x(@x)} y={y(@y + 0.5)} width={w(1)} height={h(0.5)} style={fg(@attrs, @theme)} />
        """

      # lower five eighths block
      0x2585 ->
        ~H"""
        <rect x={x(@x)} y={y(@y + 3 / 8)} width={w(1)} height={h(5 / 8)} style={fg(@attrs, @theme)} />
        """

      # lower three quarters block
      0x2586 ->
        ~H"""
        <rect x={x(@x)} y={y(@y + 1 / 4)} width={w(1)} height={h(3 / 4)} style={fg(@attrs, @theme)} />
        """

      # lower seven eighths block
      0x2587 ->
        ~H"""
        <rect x={x(@x)} y={y(@y + 1 / 8)} width={w(1)} height={h(7 / 8)} style={fg(@attrs, @theme)} />
        """

      # full block
      0x2588 ->
        ~H"""
        <rect x={x(@x)} y={y(@y)} width={w(1)} height={h(1)} style={fg(@attrs, @theme)} />
        """

      # left seven eighths block
      0x2589 ->
        ~H"""
        <rect x={x(@x)} y={y(@y)} width={w(7 / 8)} height={h(1)} style={fg(@attrs, @theme)} />
        """

      # left three quarters block
      0x258A ->
        ~H"""
        <rect x={x(@x)} y={y(@y)} width={w(3 / 4)} height={h(1)} style={fg(@attrs, @theme)} />
        """

      # left five eighths block
      0x258B ->
        ~H"""
        <rect x={x(@x)} y={y(@y)} width={w(5 / 8)} height={h(1)} style={fg(@attrs, @theme)} />
        """

      # left half block
      0x258C ->
        ~H"""
        <rect x={x(@x)} y={y(@y)} width={w(0.5)} height={h(1)} style={fg(@attrs, @theme)} />
        """

      # left three eighths block
      0x258D ->
        ~H"""
        <rect x={x(@x)} y={y(@y)} width={w(3 / 8)} height={h(1)} style={fg(@attrs, @theme)} />
        """

      # left one quarter block
      0x258E ->
        ~H"""
        <rect x={x(@x)} y={y(@y)} width={w(1 / 4)} height={h(1)} style={fg(@attrs, @theme)} />
        """

      # left one eighth block
      0x258F ->
        ~H"""
        <rect x={x(@x)} y={y(@y)} width={w(1 / 8)} height={h(1)} style={fg(@attrs, @theme)} />
        """

      # right half block
      0x2590 ->
        ~H"""
        <rect x={x(@x + 0.5)} y={y(@y)} width={w(0.5)} height={h(1)} style={fg(@attrs, @theme)} />
        """

      # light shade
      0x2591 ->
        ~H"""
        <rect
          x={x(@x)}
          y={y(@y)}
          width={w(1)}
          height={h(1)}
          style={"fill: #{mix_colors(fg_color(@attrs, @theme, true), bg_color(@attrs, @theme, true), 0.25)}"}
        />
        """

      # medium shade
      0x2592 ->
        ~H"""
        <rect
          x={x(@x)}
          y={y(@y)}
          width={w(1)}
          height={h(1)}
          style={"fill: #{mix_colors(fg_color(@attrs, @theme, true), bg_color(@attrs, @theme, true), 0.5)}"}
        />
        """

      # dark shade
      0x2593 ->
        ~H"""
        <rect
          x={x(@x)}
          y={y(@y)}
          width={w(1)}
          height={h(1)}
          style={"fill: #{mix_colors(fg_color(@attrs, @theme, true), bg_color(@attrs, @theme, true), 0.75)}"}
        />
        """

      # upper one eighth block
      0x2594 ->
        ~H"""
        <rect x={x(@x)} y={y(@y)} width={w(1)} height={h(1 / 8)} style={fg(@attrs, @theme)} />
        """

      # right one eighth block
      0x2595 ->
        ~H"""
        <rect x={x(@x + 7 / 8)} y={y(@y)} width={w(1 / 8)} height={h(1)} style={fg(@attrs, @theme)} />
        """

      # quadrant lower left
      0x2596 ->
        ~H"""
        <rect x={x(@x)} y={y(@y + 0.5)} width={w(0.5)} height={h(0.5)} style={fg(@attrs, @theme)} />
        """

      # quadrant lower right
      0x2597 ->
        ~H"""
        <rect x={x(@x + 0.5)} y={y(@y + 0.5)} width={w(0.5)} height={h(0.5)} style={fg(@attrs, @theme)} />
        """

      # quadrant upper left
      0x2598 ->
        ~H"""
        <rect x={x(@x)} y={y(@y)} width={w(0.5)} height={h(0.5)} style={fg(@attrs, @theme)} />
        """

      # quadrant upper left and lower left and lower right
      0x2599 ->
        ~H"""
        <polygon
          points={"#{x(@x)} #{y(@y)}, #{x(@x)} #{y(@y + 1)}, #{x(@x + 1)} #{y(@y + 1)}, #{x(@x + 1)} #{y(@y + 0.5)}, #{x(@x + 0.5)} #{y(@y + 0.5)}, #{x(@x + 0.5)} #{y(@y)}"}
          fill={fg_color(@attrs, @theme, true)}
        />
        """

      # quadrant upper left and lower right
      0x259A ->
        ~H"""
        <polygon
          points={"#{x(@x)} #{y(@y)}, #{x(@x)} #{y(@y + 0.5)}, #{x(@x + 1)} #{y(@y + 0.5)}, #{x(@x + 1)} #{y(@y + 1)}, #{x(@x + 0.5)} #{y(@y + 1)}, #{x(@x + 0.5)} #{y(@y)}"}
          fill={fg_color(@attrs, @theme, true)}
        />
        """

      # quadrant upper left and upper right and lower left
      0x259B ->
        ~H"""
        <polygon
          points={"#{x(@x)} #{y(@y)}, #{x(@x + 1)} #{y(@y)}, #{x(@x + 1)} #{y(@y + 0.5)}, #{x(@x + 0.5)} #{y(@y + 0.5)}, #{x(@x + 0.5)} #{y(@y + 1)}, #{x(@x)} #{y(@y + 1)}"}
          fill={fg_color(@attrs, @theme, true)}
        />
        """

      # quadrant upper left and upper right and lower right
      0x259C ->
        ~H"""
        <polygon
          points={"#{x(@x)} #{y(@y)}, #{x(@x + 1)} #{y(@y)}, #{x(@x + 1)} #{y(@y + 1)}, #{x(@x + 0.5)} #{y(@y + 1)}, #{x(@x + 0.5)} #{y(@y + 0.5)}, #{x(@x)} #{y(@y + 0.5)}"}
          fill={fg_color(@attrs, @theme, true)}
        />
        """

      # quadrant upper right
      0x259D ->
        ~H"""
        <rect x={x(@x + 0.5)} y={y(@y)} width={w(0.5)} height={h(0.5)} style={fg(@attrs, @theme)} />
        """

      # quadrant upper right and lower left
      0x259E ->
        ~H"""
        <polygon
          points={"#{x(@x + 1)} #{y(@y)}, #{x(@x + 1)} #{y(@y + 0.5)}, #{x(@x)} #{y(@y + 0.5)}, #{x(@x)} #{y(@y + 1)}, #{x(@x + 0.5)} #{y(@y + 1)}, #{x(@x + 0.5)} #{y(@y)}"}
          fill={fg_color(@attrs, @theme, true)}
        />
        """

      # quadrant upper right and lower left and lower right
      0x259F ->
        ~H"""
        <polygon
          points={"#{x(@x + 1)} #{y(@y)}, #{x(@x + 1)} #{y(@y + 1)}, #{x(@x)} #{y(@y + 1)}, #{x(@x)} #{y(@y + 0.5)}, #{x(@x + 0.5)} #{y(@y + 0.5)}, #{x(@x + 0.5)} #{y(@y)}"}
          fill={fg_color(@attrs, @theme, true)}
        />
        """

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

  defp fg(attrs, theme), do: "fill: #{fg_color(attrs, theme, true)}"

  def mix_colors(a, b, ratio), do: Colors.mix(a, b, ratio)

  defp snapshot(%{snapshot: snapshot}, nil) do
    Snapshot.new(snapshot || [])
  end

  defp snapshot(%{snapshot: snapshot}, {cols, rows}) do
    (snapshot || [])
    |> Snapshot.new()
    |> Snapshot.crop(cols, rows)
  end
end
