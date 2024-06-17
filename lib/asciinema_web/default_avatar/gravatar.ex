defmodule AsciinemaWeb.DefaultAvatar.Gravatar do
  @behaviour AsciinemaWeb.DefaultAvatar

  @size 128
  @style "retro"

  @impl true
  def url(user) do
    email = user.email || "#{user.id}@asciinema"

    hash =
      email
      |> String.downcase()
      |> Crypto.md5()

    "//gravatar.com/avatar/#{hash}?s=#{@size}&d=#{@style}"
  end
end
