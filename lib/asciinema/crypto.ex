defmodule Crypto do
  @token_alphabet "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  @token_alphabet_size byte_size(@token_alphabet)

  def md5(data) do
    Base.encode16(:erlang.md5(data), case: :lower)
  end

  def random_token(length) when is_integer(length) and length > 0 do
    # Map each random byte onto an alphanumeric character, emitting one
    # character per byte so the token is always exactly `length` characters.
    for <<byte <- :crypto.strong_rand_bytes(length)>>, into: "" do
      <<:binary.at(@token_alphabet, rem(byte, @token_alphabet_size))>>
    end
  end
end
