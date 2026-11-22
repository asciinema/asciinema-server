defmodule Asciinema.Recordings.Snapshot.Row do
  @enforce_keys [:codepoints, :attr_ids, :attrs, :widths]
  defstruct [:codepoints, :attr_ids, :attrs, :widths]
end

defimpl Enumerable, for: Asciinema.Recordings.Snapshot.Row do
  alias Asciinema.Recordings.Snapshot.Row

  def reduce(%Row{} = row, acc, fun) do
    %Row{codepoints: codepoints, attr_ids: attr_ids, attrs: attrs, widths: widths} = row
    reduce_cells(codepoints, attr_ids, attrs, widths, 0, acc, fun)
  end

  def count(%Row{codepoints: codepoints}), do: {:ok, div(byte_size(codepoints), 4)}
  def member?(_row, _value), do: {:error, __MODULE__}
  def slice(_row), do: {:error, __MODULE__}

  defp reduce_cells(_codepoints, _attr_ids, _attrs, _widths, _x, {:halt, acc}, _fun),
    do: {:halted, acc}

  defp reduce_cells(codepoints, attr_ids, attrs, widths, x, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce_cells(codepoints, attr_ids, attrs, widths, x, &1, fun)}
  end

  defp reduce_cells(<<>>, <<>>, _attrs, _widths, _x, {:cont, acc}, _fun), do: {:done, acc}

  defp reduce_cells(
         <<cp::32, codepoints::binary>>,
         <<attr_id::16, attr_ids::binary>>,
         attrs,
         widths,
         x,
         {:cont, acc},
         fun
       ) do
    width = Map.get(widths, cp, 1)
    cell = {x, cp, elem(attrs, attr_id), width}

    reduce_cells(codepoints, attr_ids, attrs, widths, x + width, fun.(cell, acc), fun)
  end
end
