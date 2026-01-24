defmodule AsciinemaWeb.DefaultAvatar.Identicon do
  use Phoenix.VerifiedRoutes,
    endpoint: AsciinemaWeb.Endpoint,
    router: AsciinemaWeb.Router

  @behaviour AsciinemaWeb.DefaultAvatar

  @impl true
  def url(user) do
    ~p"/~#{user}/avatar"
  end
end
