defmodule Asciinema.Recordings.Snapshot do
  @enforce_keys [:lines, :mode]
  defstruct [:lines, :mode]

  def new(lines, mode \\ :segments)

  def new({lines, {col, row} = _cursor}, mode) do
    lines = Enum.map(lines, &coerce_segments/1)

    %__MODULE__{lines: lines, mode: mode}
    |> regroup(:cells)
    |> invert_cell(col, row)
    |> regroup(mode)
  end

  def new({lines, nil}, mode) do
    lines = Enum.map(lines, &coerce_segments/1)

    %__MODULE__{lines: lines, mode: mode}
    |> regroup(:cells)
    |> regroup(mode)
  end

  def new(lines, mode) when is_list(lines) do
    new({lines, nil}, mode)
  end

  defp coerce_segments(segments), do: Enum.map(segments, &coerce_segment/1)

  defp coerce_segment([t, a]), do: {t, normalize_colors(a), 1}
  defp coerce_segment([t, a, w]), do: {t, normalize_colors(a), w}
  defp coerce_segment({t, a, w}), do: {t, a, w}

  defp normalize_colors(attrs) do
    attrs
    |> adjust_fg()
    |> adjust_bg()
    |> invert_colors()
  end

  defp adjust_fg(%{"bold" => true, "fg" => fg} = attrs)
       when is_integer(fg) and fg < 8 do
    Map.put(attrs, "fg", fg + 8)
  end

  defp adjust_fg(attrs), do: attrs

  defp adjust_bg(%{"blink" => true, "bg" => bg} = attrs)
       when is_integer(bg) and bg < 8 do
    Map.put(attrs, "bg", bg + 8)
  end

  defp adjust_bg(attrs), do: attrs

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

  def regroup(%__MODULE__{mode: mode} = snapshot, mode), do: snapshot

  def regroup(%__MODULE__{lines: lines}, :cells) do
    lines =
      Enum.map(lines, fn line ->
        Enum.flat_map(line, &split_segment/1)
      end)

    %__MODULE__{lines: lines, mode: :cells}
  end

  def regroup(%__MODULE__{lines: lines}, :segments) do
    lines = Enum.map(lines, &group_line_segments/1)

    %__MODULE__{lines: lines, mode: :segments}
  end

  defp split_segment([text, attrs, char_width]), do: split_segment({text, attrs, char_width})

  defp split_segment({text, attrs, char_width}) do
    text
    |> String.codepoints()
    |> Enum.map(&{&1, attrs, char_width})
  end

  defp group_line_segments([]), do: []

  defp group_line_segments([first_segment | segments]) do
    {segments, last_segment} =
      Enum.reduce(segments, {[], first_segment}, fn {char, attrs, char_width},
                                                    {segments,
                                                     {prev_char, prev_attrs, prev_char_width}} ->
        if attrs == prev_attrs && char_width == prev_char_width && char_width == 1 &&
             !special_char(char) do
          {segments, {prev_char <> char, attrs, char_width}}
        else
          {[{prev_char, prev_attrs, prev_char_width} | segments], {char, attrs, char_width}}
        end
      end)

    Enum.reverse([last_segment | segments])
  end

  @box_drawing_range Range.new(0x2500, 0x257F)
  @block_elements_range Range.new(0x2580, 0x259F)
  @braille_patterns_range Range.new(0x2800, 0x28FF)
  @powerline_triangles_range Range.new(0xE0B0, 0xE0B3)

  defp special_char(char) do
    cp = char |> String.to_charlist() |> Enum.at(0)

    Enum.member?(@box_drawing_range, cp) || Enum.member?(@block_elements_range, cp) ||
      Enum.member?(@braille_patterns_range, cp) ||
      Enum.member?(@powerline_triangles_range, cp)
  end

  @csi_init "\x1b["
  @sgr_reset "\x1b[0m"

  def seq(snapshot) do
    seq =
      snapshot
      |> regroup(:segments)
      |> Map.get(:lines)
      |> Enum.map(&line_seq/1)
      |> Enum.join("\r\n")
      |> String.replace(~r/(\r\n\s+)+$/, "")

    seq <> @csi_init <> "?25l"
  end

  defp line_seq(segments) do
    segments
    |> Enum.map(&segment_seq/1)
    |> Enum.join("")
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
        {"fg", "rgb(" <> _} -> "38;2;#{parse_rgb(v)}"
        {"fg", [r, g, b]} -> "38;2;#{r};#{g};#{b}"
        {"bg", c} when is_number(c) and c < 8 -> "4#{c}"
        {"bg", c} when is_number(c) -> "48;5;#{c}"
        {"bg", "rgb(" <> _} -> "48;2;#{parse_rgb(v)}"
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

  defp parse_rgb("rgb(" <> c) do
    c
    |> String.slice(0, String.length(c) - 1)
    |> String.split(",")
    |> Enum.join(";")
  end

  def crop(snapshot, width, height, mode \\ :segments) do
    snapshot
    |> regroup(:cells)
    |> Map.get(:lines)
    |> Enum.map(&Enum.take(&1, width))
    |> new(:cells)
    |> regroup(mode)
    |> Map.get(:lines)
    |> Enum.reverse()
    |> Enum.drop_while(&blank_line?/1)
    |> Enum.reverse()
    |> fill_to_height(height)
    |> Enum.reverse()
    |> Enum.take(height)
    |> Enum.reverse()
    |> new(mode)
  end

  defp blank_line?(line) do
    Enum.all?(line, &blank_segment?/1)
  end

  defp blank_segment?({text, attrs, _char_width}) do
    String.trim(text) == "" && attrs == %{}
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

  defp invert_cell(%__MODULE__{mode: mode} = snapshot, col, row) do
    snapshot
    |> regroup(:cells)
    |> Map.get(:lines)
    |> List.update_at(row, fn line ->
      List.update_at(line, col, fn {text, attrs, char_width} ->
        attrs = Map.put(attrs, "inverse", !(attrs["inverse"] || false))
        {text, attrs, char_width}
      end)
    end)
    |> new(:cells)
    |> regroup(mode)
  end

  def text_coords(snapshot) do
    snapshot
    |> regroup(:segments)
    |> Map.get(:lines)
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
    ~r/\s+/
    |> Regex.split(text, include_captures: true)
    |> Enum.filter(&(String.length(&1) > 0))
    |> Enum.map(&{&1, attrs, 1})
  end

  defp split_on_whitespace(segment), do: [segment]

  def bg_coords(snapshot) do
    snapshot
    |> regroup(:segments)
    |> Map.get(:lines)
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
end
