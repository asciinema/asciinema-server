defmodule AsciinemaWeb.AvatarSVG do
  def show(%{user: user}) do
    email = user.email || "#{user.id}@asciinema"

    {:safe, IdenticonSvg.generate(email, 6, :basic)}
  end
end
