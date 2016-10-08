defmodule Asciinema.Gravatar do

  def gravatar_url(email, opts \\ []) do
    hash = email
    |> String.downcase
    |> Crypto.md5

    size = Keyword.get(opts, :size, 128)
    default = Keyword.get(opts, :default, "retro")

    "//gravatar.com/avatar/#{hash}?s=#{size}&d=#{default}"
  end

end
