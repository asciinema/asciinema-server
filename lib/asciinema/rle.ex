defmodule Asciinema.Rle do
  def encode(text, marker) do
    do_encode(String.graphemes(text), marker)
  end

  defp do_encode([], _marker), do: ""

  defp do_encode([char | rest], marker) do
    do_encode(rest, marker, char, 1, "")
  end

  defp do_encode([cur | rest], marker, cur, 256, result) do
    do_encode(rest, marker, cur, 1, result <> encode_run(cur, 256, marker))
  end

  defp do_encode([cur | rest], marker, cur, count, result) do
    do_encode(rest, marker, cur, count + 1, result)
  end

  defp do_encode([char | rest], marker, cur, count, result) do
    do_encode(rest, marker, char, 1, result <> encode_run(cur, count, marker))
  end

  defp do_encode([], marker, cur, n, result) do
    result <> encode_run(cur, n, marker)
  end

  defp encode_run(marker, n, marker), do: marker <> <<n - 1::8>> <> marker
  defp encode_run(char, 1, _marker), do: char
  defp encode_run(char, 2, _marker), do: char <> char
  defp encode_run(char, 3, _marker), do: char <> char <> char
  defp encode_run(char, n, marker) when n <= 256, do: marker <> <<n - 1::8>> <> char

  def decode(text, marker) do
    do_decode(String.graphemes(text), marker, "")
  end

  defp do_decode([], _marker, result), do: result

  defp do_decode([marker, n, char | rest], marker, result) do
    do_decode(rest, marker, result <> decode_run(char, n))
  end

  defp do_decode([char | rest], marker, result) do
    do_decode(rest, marker, result <> char)
  end

  defp decode_run(char, n) do
    <<n::8>> = n

    [char]
    |> Stream.cycle()
    |> Stream.take(n + 1)
    |> Enum.join("")
  end
end
