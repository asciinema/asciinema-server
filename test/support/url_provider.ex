defmodule Asciinema.TestUrlProvider do
  @behaviour Asciinema.UrlProvider

  @impl true
  def sign_up(token) do
    "http://example.com/sign_up/#{token}"
  end

  @impl true
  def login(token) do
    "http://example.com/login/#{token}"
  end

  @impl true
  def account_deletion(token) do
    "http://example.com/account_deletion/#{token}"
  end
end
