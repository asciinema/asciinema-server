defmodule Asciinema.Leb128 do
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

  def decode(binary), do: do_decode(binary, 0, 0)

  defp do_decode(<<byte::8>>, number, shift) when byte < 128,
    do: {number + Bitwise.bsl(byte, shift), ""}

  defp do_decode(<<byte::8, rest::binary>>, number, shift) when byte < 128,
    do: {number + Bitwise.bsl(byte, shift), rest}

  defp do_decode(<<byte::8, rest::binary>>, number, shift) when byte > 127 do
    byte = Bitwise.band(byte, 127)
    do_decode(rest, number + Bitwise.bsl(byte, shift), shift + 7)
  end
end
