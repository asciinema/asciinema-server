defmodule Asciinema.Colors do
  def mix(c1, c2, ratio) do
    {r1, g1, b1} = parse(c1)
    {r2, g2, b2} = parse(c2)
    r = hex(floor(r1 * ratio + r2 * (1 - ratio)))
    g = hex(floor(g1 * ratio + g2 * (1 - ratio)))
    b = hex(floor(b1 * ratio + b2 * (1 - ratio)))

    "##{r}#{g}#{b}"
  end

  def lerp_oklab(t, {l1, a1, b1}, {l2, a2, b2}) do
    {
      l1 + t * (l2 - l1),
      a1 + t * (a2 - a1),
      b1 + t * (b2 - b1)
    }
  end

  def hex_to_oklab(hex) do
    [r, g, b] =
      hex
      |> hex_to_srgb()
      |> Enum.map(&srgb_to_linear/1)

    l = 0.412_221_470_8 * r + 0.536_332_536_3 * g + 0.051_445_992_9 * b
    m = 0.211_903_498_2 * r + 0.680_699_545_1 * g + 0.107_396_956_6 * b
    s = 0.088_302_461_9 * r + 0.281_718_837_6 * g + 0.629_978_700_5 * b

    l_ = cbrt(l)
    m_ = cbrt(m)
    s_ = cbrt(s)

    {
      0.210_454_255_3 * l_ + 0.793_617_785 * m_ - 0.004_072_046_8 * s_,
      1.977_998_495_1 * l_ - 2.428_592_205 * m_ + 0.450_593_709_9 * s_,
      0.025_904_037_1 * l_ + 0.782_771_766_2 * m_ - 0.808_675_766 * s_
    }
  end

  def oklab_to_hex(lab) do
    rgb = oklab_to_srgb(lab)

    if srgb_in_gamut?(rgb) do
      srgb_to_hex(rgb)
    else
      {l, c, h} = oklab_to_oklch(lab)
      {_, _, best} = fit_oklch_chroma(l, c, h, 24, {0.0, c, {l, 0.0, h}})

      best
      |> oklch_to_oklab()
      |> oklab_to_srgb()
      |> srgb_to_hex()
    end
  end

  def rgb_to_hex(r, g, b), do: "##{to_hex_byte(r)}#{to_hex_byte(g)}#{to_hex_byte(b)}"
  def rgb_to_hex({r, g, b}), do: rgb_to_hex(r, g, b)
  def rgb_to_hex([r, g, b]), do: rgb_to_hex(r, g, b)

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

  defp fit_oklch_chroma(_l, _c, _h, 0, {low, high, best}), do: {low, high, best}

  defp fit_oklch_chroma(l, c, h, iterations, {low, high, best}) do
    mid = (low + high) / 2
    candidate = {l, mid, h}

    if candidate |> oklch_to_oklab() |> oklab_to_srgb() |> srgb_in_gamut?() do
      fit_oklch_chroma(l, c, h, iterations - 1, {mid, high, candidate})
    else
      fit_oklch_chroma(l, c, h, iterations - 1, {low, mid, best})
    end
  end

  defp oklab_to_srgb({l, a, b}) do
    l = clamp(l, 0.0, 1.0)

    l_ = l + 0.396_337_777_4 * a + 0.215_803_757_3 * b
    m_ = l - 0.105_561_345_8 * a - 0.063_854_172_8 * b
    s_ = l - 0.089_484_177_5 * a - 1.291_485_548 * b

    l3 = l_ * l_ * l_
    m3 = m_ * m_ * m_
    s3 = s_ * s_ * s_

    r = 4.076_741_662_1 * l3 - 3.307_711_591_3 * m3 + 0.230_969_929_2 * s3
    g = -1.268_438_004_6 * l3 + 2.609_757_401_1 * m3 - 0.341_319_396_5 * s3
    b = -0.004_196_086_3 * l3 - 0.703_418_614_7 * m3 + 1.707_614_701 * s3

    {
      linear_to_srgb(r),
      linear_to_srgb(g),
      linear_to_srgb(b)
    }
  end

  defp oklab_to_oklch({l, a, b}) do
    {l, :math.sqrt(a * a + b * b), :math.atan2(b, a)}
  end

  defp oklch_to_oklab({l, c, h}) do
    {l, c * :math.cos(h), c * :math.sin(h)}
  end

  defp hex_to_srgb(<<"#", r::binary-size(2), g::binary-size(2), b::binary-size(2)>>) do
    [
      String.to_integer(r, 16) / 255,
      String.to_integer(g, 16) / 255,
      String.to_integer(b, 16) / 255
    ]
  end

  defp srgb_to_hex({r, g, b}), do: rgb_to_hex(r * 255, g * 255, b * 255)

  defp srgb_to_linear(c) when c <= 0.04045, do: c / 12.92
  defp srgb_to_linear(c), do: :math.pow((c + 0.055) / 1.055, 2.4)

  defp linear_to_srgb(c) when c <= 0.0031308, do: c * 12.92
  defp linear_to_srgb(c), do: 1.055 * :math.pow(c, 1 / 2.4) - 0.055

  defp srgb_in_gamut?({r, g, b}) do
    r >= 0 and r <= 1 and g >= 0 and g <= 1 and b >= 0 and b <= 1
  end

  defp cbrt(c) when c < 0, do: -:math.pow(-c, 1 / 3)
  defp cbrt(c), do: :math.pow(c, 1 / 3)

  defp clamp(value, low, high), do: Kernel.max(low, Kernel.min(value, high))

  defp to_hex_byte(value) do
    value
    |> clamp(0, 255)
    |> round()
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
    |> String.downcase()
  end
end
