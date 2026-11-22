defimpl Enumerable, for: Asciinema.Recordings.Snapshot do
  alias Asciinema.Recordings.Snapshot.Row

  def reduce(%{rows: rows, attrs: attrs, widths: widths}, acc, fun) do
    reduce_rows(rows, attrs, widths, acc, fun)
  end

  def count(%{rows: rows}), do: {:ok, length(rows)}
  def member?(_snapshot, _value), do: {:error, __MODULE__}
  def slice(_snapshot), do: {:error, __MODULE__}

  defp reduce_rows(_rows, _attrs, _widths, {:halt, acc}, _fun), do: {:halted, acc}

  defp reduce_rows(rows, attrs, widths, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce_rows(rows, attrs, widths, &1, fun)}
  end

  defp reduce_rows([], _attrs, _widths, {:cont, acc}, _fun), do: {:done, acc}

  defp reduce_rows([{codepoints, attr_ids} | rows], attrs, widths, {:cont, acc}, fun) do
    row = %Row{codepoints: codepoints, attr_ids: attr_ids, attrs: attrs, widths: widths}
    reduce_rows(rows, attrs, widths, fun.(row, acc), fun)
  end
end
