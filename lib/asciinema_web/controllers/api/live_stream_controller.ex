defmodule AsciinemaWeb.Api.LiveStreamController do
  use AsciinemaWeb, :controller
  import AsciinemaWeb.Auth, only: [get_basic_auth: 1]
  alias Asciinema.{Accounts, Streaming}

  plug :accepts, ~w(json)
  plug :authenticate

  def show(conn, _params) do
    if stream = Streaming.get_live_stream(conn.assigns.current_user) do
      json(conn, %{
        url: url(~p"/s/#{stream}"),
        ws_producer_url: Routes.Extra.ws_producer_url(stream)
      })
    else
      conn
      |> put_status(404)
      |> json(%{})
    end
  end

  defp authenticate(conn, _opts) do
    with {_username, api_token} <- get_basic_auth(conn),
         {:ok, token} <- Accounts.get_api_token(api_token),
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
end
