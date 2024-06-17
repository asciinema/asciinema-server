defmodule AsciinemaWeb.DefaultAvatar do
  @type url :: String.t()
  @type user :: Asciinema.User.t()

  @callback url(user) :: url

  def url(user) do
    Keyword.fetch!(Application.fetch_env!(:asciinema, __MODULE__), :adapter).url(user)
  end
end
