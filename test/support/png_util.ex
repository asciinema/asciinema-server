defmodule Asciinema.PngUtil do
  def decode_png(<<137, 80, 78, 71, 13, 10, 26, 10, rest::binary>>) do
    {chunks, <<>>} = parse_chunks(rest, [])
    {"IHDR", ihdr} = Enum.find(chunks, fn {type, _} -> type == "IHDR" end)
    {"IDAT", idat} = Enum.find(chunks, fn {type, _} -> type == "IDAT" end)
    <<width::32, height::32, 8, 2, 0, 0, 0>> = ihdr
    data = idat |> IO.iodata_to_binary() |> :zlib.uncompress()
    row_size = width * 3 + 1

    bs = byte_size(data)
    ^bs = row_size * height
    rows = decode_rows(data, width, height)

    %{width: width, height: height, rows: rows}
  end

  defp decode_rows(data, width, height) do
    row_payload_size = width * 3
    row_size = row_payload_size + 1

    {_prev_row, rows_rev} =
      data
      |> :binary.bin_to_list()
      |> Enum.chunk_every(row_size)
      |> Enum.reduce({nil, []}, fn [filter | filtered], {prev_row, rows} ->
        row =
          case filter do
            0 -> filtered
            1 -> unfilter_sub(filtered)
            2 -> unfilter_up(filtered, prev_row)
          end

        {row, [row |> :erlang.list_to_binary() | rows]}
      end)

    rows = Enum.reverse(rows_rev)
    ^height = length(rows)

    rows
  end

  defp unfilter_sub(filtered) do
    {_channel, _r, _g, _b, row_rev} =
      Enum.reduce(filtered, {0, 0, 0, 0, []}, fn value, {channel, r, g, b, acc} ->
        case channel do
          0 ->
            raw = rem(value + r, 256)
            {1, raw, g, b, [raw | acc]}

          1 ->
            raw = rem(value + g, 256)
            {2, r, raw, b, [raw | acc]}

          2 ->
            raw = rem(value + b, 256)
            {0, r, g, raw, [raw | acc]}
        end
      end)

    Enum.reverse(row_rev)
  end

  defp unfilter_up(filtered, nil), do: filtered

  defp unfilter_up(filtered, prev_row) do
    prev = :erlang.binary_to_list(prev_row)

    filtered
    |> Enum.zip(prev)
    |> Enum.map(fn {value, up} -> rem(value + up, 256) end)
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

  def cell_pixels(png, cell_x, cell_y, cell_w \\ 8, cell_h \\ 24) do
    base_x = cell_x * cell_w
    base_y = cell_y * cell_h

    for y <- base_y..(base_y + cell_h - 1),
        x <- base_x..(base_x + cell_w - 1) do
      rgb_at(png, x, y)
    end
  end

  def cell_contains_color?(png, cell_x, cell_y, color, cell_w \\ 8, cell_h \\ 24) do
    png
    |> cell_pixels(cell_x, cell_y, cell_w, cell_h)
    |> Enum.any?(&(&1 == color))
  end
end
