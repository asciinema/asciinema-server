defmodule Ext.Keyword do
  def rename(list, old, new) do
    case Keyword.pop(list, old, :not_found) do
      {:not_found, _} -> list
      {value, list} -> Keyword.put(list, new, value)
    end
  end

  def rename(list, mapping) do
    Enum.reduce(mapping, list, fn {old, new}, list ->
      rename(list, old, new)
    end)
  end
end
