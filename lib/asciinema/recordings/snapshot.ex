defmodule Asciinema.Recordings.Snapshot do
  def split_segments(lines) do
    Enum.map(lines, fn line ->
      Enum.flat_map(line, &split_segment/1)
    end)
  end

  defp split_segment([text, attrs]), do: split_segment({text, attrs})

  defp split_segment({text, attrs}) do
    text
    |> String.codepoints()
    |> Enum.map(&{&1, attrs})
  end

  def group_segments(lines), do: Enum.map(lines, &group_line_segments/1)

  defp group_line_segments([]), do: []

  defp group_line_segments([first_segment | segments]) do
    {segments, last_segment} =
      Enum.reduce(segments, {[], first_segment}, fn {text, attrs},
                                                    {segments, {prev_text, prev_attrs}} ->
        if attrs == prev_attrs do
          {segments, {prev_text <> text, attrs}}
        else
          {[{prev_text, prev_attrs} | segments], {text, attrs}}
        end
      end)

    Enum.reverse([last_segment | segments])
  end
end
