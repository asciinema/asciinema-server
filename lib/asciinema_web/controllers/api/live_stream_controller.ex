defmodule AsciinemaWeb.Api.LiveStreamController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Accounts, Streaming}
  alias AsciinemaWeb.UrlHelpers

  plug :accepts, ~w(json)
  plug :authenticate

  def show(conn, params) do
    get_stream(conn, params["id"])
  end

  def create(conn, _params) do
    # TODO add mode (config option) where new streams are actually created here
    get_stream(conn, nil)
  end

  defp get_stream(conn, id) do
    if stream = Streaming.get_live_stream(conn.assigns.current_user, id) do
      json(conn, %{
        url: url(~p"/s/#{stream}"),
        ws_producer_url: UrlHelpers.ws_producer_url(stream)
      })
    else
      conn
      |> put_status(404)
      |> json(%{reason: not_found_reason(id)})
    end
  end

  defp authenticate(conn, _opts) do
    with {_username, api_token} <- get_basic_auth(conn),
         {:ok, token} <- Accounts.fetch_api_token(api_token),
         false <- Accounts.temporary_user?(token.user) do
      assign(conn, :current_user, token.user)
    else
      _otherwise ->
        conn
        |> put_status(401)
        |> json(%{})
        |> halt()
    end
  end

  defp not_found_reason(nil), do: "stream not available for this account"
  defp not_found_reason(id), do: "stream #{id} not found"
end
