defmodule Crypto do
  def md5(data) do
    Base.encode16(:erlang.md5(data), case: :lower)
  end
end
