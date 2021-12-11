defmodule Ext.Map do
  def rename(map, old, new) do
    case Map.pop(map, old, :not_found) do
      {:not_found, _} -> map
      {value, map} -> Map.put(map, new, value)
    end
  end

  def rename(map, mapping) do
    Enum.reduce(mapping, map, fn {old, new}, map ->
      rename(map, old, new)
    end)
  end
end
