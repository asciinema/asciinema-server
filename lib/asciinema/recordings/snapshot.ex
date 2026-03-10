defmodule Asciinema.Recordings.Snapshot do
  @enforce_keys [:lines, :attrs]
  defstruct [:lines, :attrs, widths: %{}]

  def new(lines) do
    lines
    |> Enum.map(fn line -> Enum.map(line, &normalize_segment/1) end)
    |> build_dense_snapshot()
  end

  def build({lines, {col, row}}) do
    lines
    |> invert_cell(col, row)
    |> build_dense_snapshot()
  end

  def build({lines, nil}), do: build_dense_snapshot(lines)

  defp normalize_segment([t, a, w]), do: {t, a, w}
  defp normalize_segment([t, a]), do: {t, a, 1}
  defp normalize_segment({t, a, w}), do: {t, a, w}

  def normalize_colors(%__MODULE__{} = snapshot, bold_is_bright, theme) do
    {attrs, remap} =
      snapshot.attrs
      |> Tuple.to_list()
      |> Enum.reduce({[], %{}, [], 0}, fn attrs_map, {attrs, attr_ids, remap, next_id} ->
        normalized_attrs = do_normalize_colors(attrs_map, bold_is_bright, theme)

        case Map.fetch(attr_ids, normalized_attrs) do
          {:ok, id} ->
            {attrs, attr_ids, [id | remap], next_id}

          :error ->
            {[normalized_attrs | attrs], Map.put(attr_ids, normalized_attrs, next_id),
             [next_id | remap], next_id + 1}
        end
      end)
      |> then(fn {attrs, _attr_ids, remap, _next_id} ->
        {attrs |> Enum.reverse() |> List.to_tuple(), remap |> Enum.reverse() |> List.to_tuple()}
      end)

    lines =
      Enum.map(snapshot.lines, fn {codepoints, attr_ids} ->
        remapped_attr_ids =
          for <<attr_id::16 <- attr_ids>>, into: <<>> do
            <<elem(remap, attr_id)::16>>
          end

        {codepoints, remapped_attr_ids}
      end)

    %__MODULE__{snapshot | lines: lines, attrs: attrs}
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

  defp build_dense_snapshot(cell_lines) do
    {attrs, _attr_ids, _next_id, widths, lines} =
      Enum.reduce(cell_lines, {[], %{}, 0, %{}, []}, fn line,
                                                        {attrs, attr_ids, next_id, widths, lines} ->
        {attrs, attr_ids, next_id, widths, dense_line} =
          build_dense_line(line, attrs, attr_ids, next_id, widths)

        {attrs, attr_ids, next_id, widths, [dense_line | lines]}
      end)

    %__MODULE__{
      lines: Enum.reverse(lines),
      attrs: attrs |> Enum.reverse() |> List.to_tuple(),
      widths: widths
    }
  end

  defp build_dense_line(line, attrs, attr_ids, next_id, widths) do
    {attrs, attr_ids, next_id, widths, codepoints, line_attr_ids} =
      Enum.reduce(
        line,
        {attrs, attr_ids, next_id, widths, [], []},
        fn {text, attrs_map, char_width},
           {attrs, attr_ids, next_id, widths, codepoints, line_attr_ids} ->
          codepoint = codepoint(text)

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
              Map.put(widths, codepoint, char_width)
            end

          {attrs, attr_ids, next_id, widths, [<<codepoint::32>> | codepoints],
           [<<attr_id::16>> | line_attr_ids]}
        end
      )

    dense_line =
      {codepoints |> Enum.reverse() |> IO.iodata_to_binary(),
       line_attr_ids |> Enum.reverse() |> IO.iodata_to_binary()}

    {attrs, attr_ids, next_id, widths, dense_line}
  end

  @csi_init "\x1b["
  @sgr_reset "\x1b[0m"

  def seq(snapshot) do
    seq =
      snapshot
      |> Enum.map(&line_seq/1)
      |> Enum.join("\r\n")
      |> String.trim_trailing("\r\n")

    seq <> @csi_init <> "?25l"
  end

  defp line_seq(line) do
    {segments, pending} =
      Enum.reduce(line, {[], nil}, fn {_x, cp, cell_attrs, _width}, {segments, pending} ->
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

  def crop(%__MODULE__{} = snapshot, width, height) do
    lines =
      snapshot
      |> Map.get(:lines)
      |> Enum.map(&crop_line(&1, width))
      |> Enum.reverse()
      |> Enum.drop_while(&blank_line?(&1, snapshot.attrs))
      |> Enum.reverse()
      |> fill_to_height(height)
      |> Enum.reverse()
      |> Enum.take(height)
      |> Enum.reverse()

    %__MODULE__{snapshot | lines: lines}
  end

  defp crop_line({codepoints, attr_ids}, width) do
    width = min(width, div(byte_size(codepoints), 4))

    {
      binary_part(codepoints, 0, width * 4),
      binary_part(attr_ids, 0, width * 2)
    }
  end

  defp blank_line?({codepoints, attr_ids}, attrs) do
    blank_line?(codepoints, attr_ids, attrs)
  end

  defp blank_line?(<<>>, <<>>, _attrs), do: true

  defp blank_line?(
         <<cp::32, codepoints::binary>>,
         <<attr_id::16, attr_ids::binary>>,
         attrs
       ) do
    cell_attrs = elem(attrs, attr_id)

    cp == 0x20 &&
      cell_attrs["bg"] == nil &&
      blank_line?(codepoints, attr_ids, attrs)
  end

  defp fill_to_height(lines, height) do
    if height - Enum.count(lines) > 0 do
      enums = [lines, Stream.cycle([empty_line()])]

      enums
      |> Stream.concat()
      |> Enum.take(height)
    else
      lines
    end
  end

  defp empty_line, do: {<<>>, <<>>}

  defp invert_cell(lines, col, row) do
    List.update_at(lines, row, fn line ->
      case cell_index_at_col(line, col) do
        nil ->
          line

        index ->
          List.update_at(line, index, fn {text, attrs, char_width} ->
            attrs = Map.put(attrs, "inverse", !(attrs["inverse"] || false))
            {text, attrs, char_width}
          end)
      end
    end)
  end

  defp cell_index_at_col(line, col) when is_integer(col) and col >= 0 do
    do_cell_index_at_col(line, col, 0, 0)
  end

  defp cell_index_at_col(_line, _col), do: nil

  defp do_cell_index_at_col([], _col, _offset, _index), do: nil

  defp do_cell_index_at_col([{_, _, char_width} | rest], col, offset, index) do
    if col < offset + char_width do
      index
    else
      do_cell_index_at_col(rest, col, offset + char_width, index + 1)
    end
  end

  defp codepoint(<<cp::utf8>>), do: cp
end
