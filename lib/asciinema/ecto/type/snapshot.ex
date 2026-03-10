defmodule Asciinema.Ecto.Type.Snapshot do
  use Ecto.Type
  alias Asciinema.Recordings.Snapshot

  def type, do: :text

  def cast({lines, cursor}) when is_list(lines) do
    {:ok, Snapshot.build({line_cells(lines), cursor})}
  end

  def load(value) do
    snapshot =
      value
      |> Jason.decode!()
      |> line_cells()
      |> Snapshot.new()

    {:ok, snapshot}
  end

  def dump(%Snapshot{} = value) do
    value
    |> Enum.map(&line_segments/1)
    |> Jason.encode()
  end

  defp line_segments(line) do
    {segments, pending} =
      Enum.reduce(line, {[], nil}, fn {_x, cp, cell_attrs, cell_width}, {segments, pending} ->
        char = <<cp::utf8>>

        case pending do
          nil ->
            {segments, {[char], cell_attrs, cell_width}}

          {chars, ^cell_attrs, ^cell_width} ->
            {segments, {[char | chars], cell_attrs, cell_width}}

          {chars, attrs, width} ->
            {[segment(chars, attrs, width) | segments], {[char], cell_attrs, cell_width}}
        end
      end)

    segments =
      case pending do
        nil -> segments
        {chars, attrs, width} -> [segment(chars, attrs, width) | segments]
      end

    Enum.reverse(segments)
  end

  defp segment(chars, attrs, width) do
    text =
      chars
      |> Enum.reverse()
      |> IO.iodata_to_binary()

    [text, attrs, width]
  end

  defp line_cells(lines) do
    Enum.map(lines, &segments_line_to_cells/1)
  end

  defp segments_line_to_cells(line) do
    line
    |> Enum.reduce([], &segment_cells/2)
    |> Enum.reverse()
  end

  defp segment_cells([text, attrs, char_width], acc) do
    segment_cells({text, attrs, char_width}, acc)
  end

  defp segment_cells([text, attrs], acc) do
    segment_cells({text, attrs, 1}, acc)
  end

  defp segment_cells({text, attrs, char_width}, acc) do
    split_text_to_cells(text, attrs, char_width, acc)
  end

  defp split_text_to_cells(<<>>, _attrs, _char_width, acc), do: acc

  defp split_text_to_cells(<<cp::utf8, rest::binary>>, attrs, char_width, acc) do
    split_text_to_cells(rest, attrs, char_width, [{<<cp::utf8>>, attrs, char_width} | acc])
  end
end
