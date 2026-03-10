defimpl Enumerable, for: Asciinema.Recordings.Snapshot do
  alias Asciinema.Recordings.Snapshot.Line

  def reduce(%{lines: lines, attrs: attrs, widths: widths}, acc, fun) do
    reduce_lines(lines, attrs, widths, acc, fun)
  end

  def count(%{lines: lines}), do: {:ok, length(lines)}
  def member?(_snapshot, _value), do: {:error, __MODULE__}
  def slice(_snapshot), do: {:error, __MODULE__}

  defp reduce_lines(_lines, _attrs, _widths, {:halt, acc}, _fun), do: {:halted, acc}

  defp reduce_lines(lines, attrs, widths, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce_lines(lines, attrs, widths, &1, fun)}
  end

  defp reduce_lines([], _attrs, _widths, {:cont, acc}, _fun), do: {:done, acc}

  defp reduce_lines([{codepoints, attr_ids} | lines], attrs, widths, {:cont, acc}, fun) do
    line = %Line{codepoints: codepoints, attr_ids: attr_ids, attrs: attrs, widths: widths}
    reduce_lines(lines, attrs, widths, fun.(line, acc), fun)
  end
end
