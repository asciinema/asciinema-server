defmodule Asciinema.PngUtil do
  def decode_png(<<137, 80, 78, 71, 13, 10, 26, 10, rest::binary>>) do
    {chunks, <<>>} = parse_chunks(rest, [])
    {"IHDR", ihdr} = Enum.find(chunks, fn {type, _} -> type == "IHDR" end)
    {"IDAT", idat} = Enum.find(chunks, fn {type, _} -> type == "IDAT" end)
    <<width::32, height::32, 8, 2, 0, 0, 0>> = ihdr
    data = idat |> IO.iodata_to_binary() |> :zlib.uncompress()
    rows = for <<0, row::binary-size(width * 3) <- data>>, do: row
    row_size = width * 3 + 1

    bs = byte_size(data)
    ^bs = row_size * height
    len = length(rows)
    ^len = height

    %{width: width, height: height, rows: rows}
  end

  defp parse_chunks(<<>>, acc), do: {Enum.reverse(acc), <<>>}

  defp parse_chunks(
         <<size::32, type::binary-size(4), data::binary-size(size), _crc::32, rest::binary>>,
         acc
       ) do
    parse_chunks(rest, [{type, data} | acc])
  end

  def rgb_at(%{rows: rows}, x, y) do
    row = Enum.at(rows, y)
    <<_::binary-size(x * 3), r, g, b, _::binary>> = row

    {r, g, b}
  end
end
