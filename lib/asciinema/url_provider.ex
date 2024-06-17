defmodule Asciinema.UrlProvider do
  @type token :: String.t()
  @type url :: String.t()

  @callback sign_up(token) :: url
  @callback login(token) :: url
  @callback account_deletion(token) :: url
end
