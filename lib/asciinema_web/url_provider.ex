defmodule AsciinemaWeb.UrlProvider do
  use Phoenix.VerifiedRoutes,
    endpoint: AsciinemaWeb.Endpoint,
    router: AsciinemaWeb.Router

  @behaviour Asciinema.UrlProvider

  @impl true
  def sign_up(token) do
    url(~p"/users/new?t=#{token}")
  end

  @impl true
  def login(token) do
    url(~p"/session/new?t=#{token}")
  end

  @impl true
  def account_deletion(token) do
    url(~p"/user/delete?t=#{token}")
  end
end
