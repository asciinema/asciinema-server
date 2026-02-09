defmodule Asciinema.Recordings.Snapshot do
  @enforce_keys [:lines]
  defstruct [:lines]

  def new(lines, input_mode \\ :cells) do
    lines = Enum.map(lines, fn segments -> Enum.map(segments, &normalize_segment/1) end)

    lines =
      case input_mode do
        :cells -> lines
        :segments -> segments_to_cells(lines)
      end

    %__MODULE__{lines: lines}
  end

  def build({lines, {col, row} = _cursor}, mode) do
    lines = Enum.map(lines, fn segments -> Enum.map(segments, &normalize_segment/1) end)

    %__MODULE__{lines: lines}
    |> segments_to_cells(mode)
    |> invert_cell(col, row)
    |> Map.get(:lines)
    |> Enum.map(fn segments -> Enum.map(segments, &normalize_segment/1) end)
    |> new(:cells)
  end

  def build({lines, nil}, mode) do
    lines = Enum.map(lines, fn segments -> Enum.map(segments, &normalize_segment/1) end)

    %__MODULE__{lines: lines}
    |> segments_to_cells(mode)
  end

  defp normalize_segment([t, a, w]), do: {t, a, w}
  defp normalize_segment([t, a]), do: {t, a, 1}
  defp normalize_segment({t, a, w}), do: {t, a, w}

  def normalize_colors(snapshot, bold_is_bright) do
    Map.update(snapshot, :lines, [], fn lines ->
      Enum.map(lines, fn segments ->
        Enum.map(segments, fn {t, a, w} ->
          {t, do_normalize_colors(a, bold_is_bright), w}
        end)
      end)
    end)
  end

  defp do_normalize_colors(attrs, true) do
    attrs
    |> adjust_fg()
    |> invert_colors()
  end

  defp do_normalize_colors(attrs, false), do: invert_colors(attrs)

  defp adjust_fg(%{"bold" => true, "fg" => fg} = attrs)
       when is_integer(fg) and fg < 8 do
    Map.put(attrs, "fg", fg + 8)
  end

  defp adjust_fg(attrs), do: attrs

  @default_fg_code 7
  @default_bg_code 0

  defp invert_colors(%{"inverse" => true} = attrs) do
    fg = attrs["bg"] || @default_bg_code
    bg = attrs["fg"] || @default_fg_code

    attrs
    |> Map.merge(%{"fg" => fg, "bg" => bg})
    |> Map.delete("inverse")
  end

  defp invert_colors(attrs), do: attrs

  def segments_to_cells(%__MODULE__{} = snapshot, :cells), do: snapshot
  def segments_to_cells(%__MODULE__{} = snapshot, :segments), do: segments_to_cells(snapshot)

  def segments_to_cells(%__MODULE__{lines: lines}) do
    %__MODULE__{lines: segments_to_cells(lines)}
  end

  def segments_to_cells(lines) when is_list(lines) do
    Enum.map(lines, fn line ->
      Enum.flat_map(line, &split_segment/1)
    end)
  end

  defp cells_to_segments(lines, split_specials) do
    Enum.map(lines, &group_line_segments(&1, split_specials))
  end

  def to_segments(%__MODULE__{} = snapshot, opts \\ []) do
    split_specials = Keyword.get(opts, :split_specials, false)
    cells_to_segments(snapshot.lines, split_specials)
  end

  defp split_segment([text, attrs, char_width]), do: split_segment({text, attrs, char_width})
  defp split_segment([text, attrs]), do: split_segment({text, attrs, 1})

  defp split_segment({text, attrs, char_width}) do
    text
    |> String.codepoints()
    |> Enum.map(&{&1, attrs, char_width})
  end

  defp group_line_segments([], _split_specials), do: []

  defp group_line_segments(cells, split_specials) do
    {segments, last_segment} =
      Enum.reduce(cells, {[], nil}, fn {cur_char, cur_attrs, cur_char_width} = current,
                                       {segments, prev} ->
        if split_specials && (cur_char_width > 1 || special_char(cur_char)) do
          {[current, prev | segments], nil}
        else
          case prev do
            {prev_chars, prev_attrs, prev_char_width} ->
              if cur_attrs == prev_attrs && cur_char_width == prev_char_width do
                {segments, {prev_chars <> cur_char, prev_attrs, prev_char_width}}
              else
                {[prev | segments], current}
              end

            nil ->
              {segments, current}
          end
        end
      end)

    [last_segment | segments]
    |> Enum.filter(& &1)
    |> Enum.reverse()
  end

  @box_drawing_range Range.new(0x2500, 0x257F)
  @block_elements_range Range.new(0x2580, 0x259F)
  @black_square 0x25A0
  @sextants_range Range.new(0x1FB00, 0x1FB3B)
  @braille_patterns_range Range.new(0x2800, 0x28FF)
  @powerline_triangles_range Range.new(0xE0B0, 0xE0B3)

  defp special_char(char) do
    cp = char |> String.to_charlist() |> Enum.at(0)

    Enum.member?(@box_drawing_range, cp) || Enum.member?(@block_elements_range, cp) ||
      cp == @black_square ||
      Enum.member?(@sextants_range, cp) ||
      Enum.member?(@braille_patterns_range, cp) ||
      Enum.member?(@powerline_triangles_range, cp)
  end

  def graphic_char?(char) do
    cp = char |> String.to_charlist() |> Enum.at(0)

    Enum.member?(@block_elements_range, cp) ||
      cp == @black_square ||
      Enum.member?(@sextants_range, cp) ||
      Enum.member?(@powerline_triangles_range, cp)
  end

  @csi_init "\x1b["
  @sgr_reset "\x1b[0m"

  def seq(snapshot) do
    seq =
      snapshot
      |> to_segments()
      |> Enum.map_join("\r\n", &line_seq/1)
      |> String.replace(~r/(\r\n\s+)+$/, "")

    seq <> @csi_init <> "?25l"
  end

  defp line_seq(segments) do
    segments
    |> Enum.map_join("", &segment_seq/1)
    |> String.replace(~r/\e\[0m\s*$/, "\e[0m")
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
    snapshot
    |> Map.get(:lines)
    |> Enum.map(&Enum.take(&1, width))
    |> Enum.reverse()
    |> Enum.drop_while(&blank_line?/1)
    |> Enum.reverse()
    |> fill_to_height(height)
    |> Enum.reverse()
    |> Enum.take(height)
    |> Enum.reverse()
    |> new(:cells)
  end

  defp blank_line?(line) do
    Enum.all?(line, &blank_segment?/1)
  end

  defp blank_segment?({text, attrs, _char_width}) do
    String.trim(text) == "" && attrs["bg"] == nil
  end

  defp fill_to_height(lines, height) do
    if height - Enum.count(lines) > 0 do
      enums = [lines, Stream.cycle([[]])]

      enums
      |> Stream.concat()
      |> Enum.take(height)
    else
      lines
    end
  end

  defp invert_cell(%__MODULE__{} = snapshot, col, row) do
    snapshot
    |> Map.get(:lines)
    |> List.update_at(row, fn line ->
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
    |> new(:cells)
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
end
