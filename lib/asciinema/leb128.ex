defmodule Asciinema.Leb128 do
  import Bitwise

  def encode(number), do: do_encode(number, <<>>)

  defp do_encode(number, binary) do
    low = Bitwise.band(number, 127)
    number = Bitwise.bsr(number, 7)

    if number > 0 do
      low = Bitwise.bor(low, 128)
      do_encode(number, <<binary::binary, low::8>>)
    else
      <<binary::binary, low::8>>
    end
  end

  def decode(binary, opts \\ []) do
    max_bytes = Keyword.get(opts, :max_bytes)
    max_value = Keyword.get(opts, :max_value)

    do_decode(binary, 0, 0, 0, max_bytes, max_value)
  end

  defp do_decode(<<byte::8, rest::binary>>, number, shift, count, max_bytes, max_value)
       when is_nil(max_bytes) or count < max_bytes do
    number = number + bsl(band(byte, 127), shift)

    cond do
      byte >= 128 -> do_decode(rest, number, shift + 7, count + 1, max_bytes, max_value)
      not is_nil(max_value) and number > max_value -> {:error, :varint_overflow}
      true -> {:ok, number, rest}
    end
  end

  defp do_decode(<<_::8, _::binary>>, _number, _shift, _count, _max_bytes, _max_value),
    do: {:error, :varint_too_long}

  defp do_decode(<<>>, _number, _shift, _count, _max_bytes, _max_value),
    do: {:error, :truncated_varint}
end
