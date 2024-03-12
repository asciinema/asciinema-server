defmodule Asciinema.Recordings.Markers do
  def validate(_, markers) do
    case parse(markers) do
      {:ok, _} -> []
      {:error, index} -> [markers: "invalid syntax in line #{index + 1}"]
    end
  end

  def parse(markers) do
    results =
      markers
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(&parse_one/1)

    case Enum.find_index(results, fn result -> result == :error end) do
      nil -> {:ok, results}
      index -> {:error, index}
    end
  end

  defp parse_one(marker) do
    parts =
      marker
      |> String.trim()
      |> String.split(~r/\s+-\s+/, parts: 2)
      |> Kernel.++([""])
      |> Enum.take(2)

    with [t, l] <- parts,
         {t, ""} <- Float.parse(t),
         true <- String.length(l) < 100 do
      {t, l}
    else
      _ -> :error
    end
  end
end
