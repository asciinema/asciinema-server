defmodule Asciinema.Recordings.Snapshot do
  @enforce_keys [:rows, :attrs]
  defstruct [:rows, :attrs, widths: %{}, cursor: nil]

  @doc "Builds dense rows from text/style/width segments, preserving the cursor separately."
  def from_segments(rows, cursor \\ nil) do
    {attrs, _attr_ids, _next_id, widths, rows} =
      Enum.reduce(rows, {[], %{}, 0, %{}, []}, fn row, {attrs, attr_ids, next_id, widths, rows} ->
        {attrs, attr_ids, next_id, widths, dense_row} =
          build_dense_row(row, attrs, attr_ids, next_id, widths)

        {attrs, attr_ids, next_id, widths, [dense_row | rows]}
      end)

    %__MODULE__{
      rows: Enum.reverse(rows),
      attrs: attrs |> Enum.reverse() |> List.to_tuple(),
      widths: widths,
      cursor: cursor
    }
  end

  defp normalize_segment([t, a, w]), do: {t, a, w}
  defp normalize_segment([t, a]), do: {t, a, 1}
  defp normalize_segment({t, a, w}), do: {t, a, w}
  defp normalize_segment({t, a}), do: {t, a, 1}

  def normalize_colors(%__MODULE__{} = snapshot, bold_is_bright, theme) do
    attrs =
      snapshot.attrs
      |> Tuple.to_list()
      |> Enum.map(&do_normalize_colors(&1, bold_is_bright, theme))
      |> List.to_tuple()

    %__MODULE__{snapshot | attrs: attrs}
  end

  defp do_normalize_colors(attrs, true, theme) do
    attrs
    |> adjust_fg()
    |> invert_colors(theme)
  end

  defp do_normalize_colors(attrs, false, theme), do: invert_colors(attrs, theme)

  defp adjust_fg(%{"bold" => true, "fg" => fg} = attrs)
       when is_integer(fg) and fg < 8 do
    Map.put(attrs, "fg", fg + 8)
  end

  defp adjust_fg(attrs), do: attrs

  defp invert_colors(%{"inverse" => true} = attrs, theme) do
    fg = attrs["bg"] || theme.bg
    bg = attrs["fg"] || theme.fg

    attrs
    |> Map.merge(%{"fg" => fg, "bg" => bg})
    |> Map.delete("inverse")
  end

  defp invert_colors(attrs, _theme), do: attrs

  defp build_dense_row(row, attrs, attr_ids, next_id, widths) do
    {attrs, attr_ids, next_id, widths, codepoints, row_attr_ids} =
      Enum.reduce(
        row,
        {attrs, attr_ids, next_id, widths, [], []},
        fn segment, {attrs, attr_ids, next_id, widths, codepoints, row_attr_ids} ->
          {text, attrs_map, char_width} = normalize_segment(segment)
          encoded = for <<cp::utf8 <- text>>, into: <<>>, do: <<cp::32>>

          {attr_id, attrs, attr_ids, next_id} =
            case Map.fetch(attr_ids, attrs_map) do
              {:ok, attr_id} ->
                {attr_id, attrs, attr_ids, next_id}

              :error ->
                {next_id, [attrs_map | attrs], Map.put(attr_ids, attrs_map, next_id), next_id + 1}
            end

          widths =
            if char_width == 1 do
              widths
            else
              for <<cp::32 <- encoded>>, reduce: widths do
                widths -> Map.put(widths, cp, char_width)
              end
            end

          ids = :binary.copy(<<attr_id::16>>, div(byte_size(encoded), 4))

          {attrs, attr_ids, next_id, widths, [encoded | codepoints], [ids | row_attr_ids]}
        end
      )

    dense_row =
      {codepoints |> Enum.reverse() |> IO.iodata_to_binary(),
       row_attr_ids |> Enum.reverse() |> IO.iodata_to_binary()}

    {attrs, attr_ids, next_id, widths, dense_row}
  end

  def to_segments(snapshot), do: Enum.map(snapshot, &row_segments/1)

  defp row_segments(row) do
    {segments, pending} =
      Enum.reduce(row, {[], nil}, fn {_x, cp, attrs, width}, {segments, pending} ->
        char = <<cp::utf8>>

        case pending do
          nil -> {segments, {[char], attrs, width}}
          {chars, ^attrs, ^width} -> {segments, {[char | chars], attrs, width}}
          previous -> {[segment(previous) | segments], {[char], attrs, width}}
        end
      end)

    segments = if pending, do: [segment(pending) | segments], else: segments
    Enum.reverse(segments)
  end

  defp segment({chars, attrs, width}), do: [chars_to_text(chars), attrs, width]

  @csi_init "\x1b["
  @sgr_reset "\x1b[0m"

  @doc "Emits terminal content followed by cursor position and visibility."
  def to_ansi(snapshot) do
    seq =
      snapshot
      |> Enum.map_join("\r\n", &row_ansi/1)
      |> String.trim_trailing("\r\n")

    case snapshot.cursor do
      nil -> seq <> @csi_init <> "?25l"
      {col, row} -> seq <> "#{@csi_init}#{row + 1};#{col + 1}H#{@csi_init}?25h"
    end
  end

  defp row_ansi(row) do
    {segments, pending} =
      Enum.reduce(row, {[], nil}, fn {_x, cp, cell_attrs, _width}, {segments, pending} ->
        char = <<cp::utf8>>

        case pending do
          nil ->
            {segments, {[char], cell_attrs}}

          {chars, ^cell_attrs} ->
            {segments, {[char | chars], cell_attrs}}

          {chars, attrs} ->
            {[segment_seq({chars_to_text(chars), attrs, 1}) | segments], {[char], cell_attrs}}
        end
      end)

    segments =
      case pending do
        nil -> segments
        {chars, attrs} -> [segment_seq({chars_to_text(chars), attrs, 1}) | segments]
      end

    segments
    |> Enum.reverse()
    |> IO.iodata_to_binary()
    |> String.trim_trailing(" ")
  end

  defp chars_to_text(chars) do
    chars
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  defp segment_seq({text, attrs, _char_width}) do
    params =
      attrs
      |> Enum.reject(fn {_k, v} -> v == false end)
      |> sgr_params()

    case params do
      [] ->
        text

      params ->
        @csi_init <> Enum.join(params, ";") <> "m" <> text <> @sgr_reset
    end
  end

  defp sgr_params([{k, v} | rest]) do
    param =
      case {k, v} do
        {"fg", c} when is_number(c) and c < 8 -> "3#{c}"
        {"fg", c} when is_number(c) -> "38;5;#{c}"
        {"fg", "#" <> _} -> "38;2;#{parse_hex_color(v)}"
        {"fg", "rgb(" <> _} -> "38;2;#{parse_rgb_color(v)}"
        {"fg", [r, g, b]} -> "38;2;#{r};#{g};#{b}"
        {"bg", c} when is_number(c) and c < 8 -> "4#{c}"
        {"bg", c} when is_number(c) -> "48;5;#{c}"
        {"bg", "#" <> _} -> "48;2;#{parse_hex_color(v)}"
        {"bg", "rgb(" <> _} -> "48;2;#{parse_rgb_color(v)}"
        {"bg", [r, g, b]} -> "48;2;#{r};#{g};#{b}"
        {"bold", true} -> "1"
        {"faint", true} -> "2"
        {"italic", true} -> "3"
        {"underline", true} -> "4"
        {"blink", true} -> "5"
        {"inverse", true} -> "7"
        {"strikethrough", true} -> "9"
      end

    [param | sgr_params(rest)]
  end

  defp sgr_params([]), do: []

  defp parse_hex_color(<<"#", r::binary-size(2), g::binary-size(2), b::binary-size(2)>>) do
    r = String.to_integer(r, 16)
    g = String.to_integer(g, 16)
    b = String.to_integer(b, 16)

    "#{r};#{g};#{b}"
  end

  defp parse_rgb_color("rgb(" <> c) do
    c
    |> String.slice(0, String.length(c) - 1)
    |> String.split(",")
    |> Enum.join(";")
  end

  @doc "Clips to display columns, trims blank trailing rows, and keeps the bottom viewport."
  def crop_for_thumbnail(%__MODULE__{} = snapshot, width, height)
      when width > 0 and height > 0 do
    cursor =
      case snapshot.cursor do
        {x, y} when x >= 0 and x < width and y >= 0 ->
          if y < length(snapshot.rows), do: {x, y}

        _ ->
          nil
      end

    rows =
      snapshot.rows
      |> Enum.map(&crop_row(&1, width, snapshot.widths))
      |> Enum.with_index()
      |> Enum.reverse()
      |> Enum.drop_while(fn {row, y} ->
        not match?({_, ^y}, cursor) and blank_row?(row, snapshot.attrs)
      end)
      |> Enum.reverse()
      |> Enum.map(&elem(&1, 0))

    offset = max(length(rows) - height, 0)
    rows = Enum.drop(rows, offset)
    rows = rows ++ List.duplicate({<<>>, <<>>}, height - length(rows))

    cursor =
      case cursor do
        {x, y} when y >= offset -> {x, y - offset}
        _ -> nil
      end

    %__MODULE__{snapshot | rows: rows, cursor: cursor}
  end

  defp crop_row({codepoints, ids}, width, widths) do
    {count, remaining} = fitting_cells(codepoints, width, widths, 0)
    prefix = binary_part(codepoints, 0, count * 4)
    attr_ids = binary_part(ids, 0, count * 2)

    # A wide character cut by the viewport becomes spaces with its background.
    if remaining > 0 and count * 4 < byte_size(codepoints) do
      id = binary_part(ids, count * 2, 2)
      {prefix <> :binary.copy(<<32::32>>, remaining), attr_ids <> :binary.copy(id, remaining)}
    else
      {prefix, attr_ids}
    end
  end

  defp fitting_cells(<<cp::32, rest::binary>>, remaining, widths, count) do
    width = Map.get(widths, cp, 1)

    if width <= remaining,
      do: fitting_cells(rest, remaining - width, widths, count + 1),
      else: {count, remaining}
  end

  defp fitting_cells(<<>>, remaining, _widths, count), do: {count, remaining}

  defp blank_row?({codepoints, attr_ids}, attrs), do: blank_row?(codepoints, attr_ids, attrs)
  defp blank_row?(<<>>, <<>>, _attrs), do: true

  defp blank_row?(
         <<cp::32, codepoints::binary>>,
         <<attr_id::16, attr_ids::binary>>,
         attrs
       ) do
    cell_attrs = elem(attrs, attr_id)

    cp == 0x20 &&
      cell_attrs["bg"] == nil &&
      cell_attrs["inverse"] != true &&
      blank_row?(codepoints, attr_ids, attrs)
  end
end
