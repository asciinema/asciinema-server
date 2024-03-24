defmodule Asciinema.Colors do
  def mix(
        <<"#", r1::binary-size(2), g1::binary-size(2), b1::binary-size(2)>>,
        <<"#", r2::binary-size(2), g2::binary-size(2), b2::binary-size(2)>>,
        ratio
      ) do
    r1 = String.to_integer(r1, 16)
    g1 = String.to_integer(g1, 16)
    b1 = String.to_integer(b1, 16)
    r2 = String.to_integer(r2, 16)
    g2 = String.to_integer(g2, 16)
    b2 = String.to_integer(b2, 16)
    r = hex(floor(r1 * ratio + r2 * (1 - ratio)))
    g = hex(floor(g1 * ratio + g2 * (1 - ratio)))
    b = hex(floor(b1 * ratio + b2 * (1 - ratio)))

    "##{r}#{g}#{b}"
  end

  def hex(r, g, b), do: "##{hex(r)}#{hex(g)}#{hex(b)}"
  def hex([r, g, b]), do: hex(r, g, b)

  def hex(int) do
    int
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end
end
