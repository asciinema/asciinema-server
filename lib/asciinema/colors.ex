defmodule Asciinema.Colors do
  def mix(c1, c2, ratio) do
    {r1, g1, b1} = parse(c1)
    {r2, g2, b2} = parse(c2)
    r = hex(floor(r1 * ratio + r2 * (1 - ratio)))
    g = hex(floor(g1 * ratio + g2 * (1 - ratio)))
    b = hex(floor(b1 * ratio + b2 * (1 - ratio)))

    "##{r}#{g}#{b}"
  end

  def hex(r, g, b), do: "##{hex(r)}#{hex(g)}#{hex(b)}"
  def hex({r, g, b}), do: hex(r, g, b)
  def hex([r, g, b]), do: hex(r, g, b)

  def hex(int) when is_integer(int) do
    int
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
    |> String.downcase()
  end

  def parse(<<"#", r::binary-size(2), g::binary-size(2), b::binary-size(2)>>) do
    {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
  end

  def parse("rgb(" <> rest) do
    rest
    |> String.slice(0, String.length(rest) - 1)
    |> String.split(",", parts: 3)
    |> Enum.map(&String.to_integer(String.trim(&1)))
    |> List.to_tuple()
  end
end
