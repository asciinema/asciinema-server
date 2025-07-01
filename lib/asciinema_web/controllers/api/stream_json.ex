defmodule AsciinemaWeb.Api.StreamJSON do
  use AsciinemaWeb, :json
  alias AsciinemaWeb.UrlHelpers

  def show(%{stream: stream}) do
    %{
      url: url(~p"/s/#{stream}"),
      ws_producer_url: UrlHelpers.ws_producer_url(stream)
    }
  end

  def error(%{reason: reason}) do
    %{reason: reason}
  end
end
