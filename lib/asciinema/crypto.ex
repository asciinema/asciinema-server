defmodule Crypto do
  def md5(data) do
    Base.encode16(:erlang.md5(data), case: :lower)
  end

  def random_token(length) do
    length
    |> :crypto.strong_rand_bytes
    |> Base.url_encode64
    |> String.replace(~r/[_=-]/, "")
    |> binary_part(0, length)
  end
end
