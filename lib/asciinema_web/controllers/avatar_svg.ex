defmodule AsciinemaWeb.AvatarSVG do
  def show(%{user: user}) do
    email = user.email || "#{user.id}@asciinema"

    {:safe, IdenticonSvg.generate(email, 7, :split2, 1.0, 1)}
  end
end
