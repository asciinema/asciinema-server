defmodule Asciinema.HttpUtil do
  def download_to(url, path, http_options \\ []) do
    url = String.to_charlist(url)
    path = String.to_charlist(path)

    http_options =
      Keyword.merge(
        [
          connect_timeout: 5_000,
          timeout: 15_000,
          autoredirect: true,
          ssl: [{:verify, :verify_peer}, {:cacerts, :public_key.cacerts_get()}]
        ],
        http_options
      )

    options = [stream: path]

    with {:ok, {{_http, 200, _reason}, _resp_headers, :saved_to_file}} <-
           :httpc.request(:get, {url, []}, http_options, options) do
      :ok
    end
  end
end
