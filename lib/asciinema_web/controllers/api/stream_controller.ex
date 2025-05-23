defmodule AsciinemaWeb.Api.StreamController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Accounts, Streaming}
  alias AsciinemaWeb.UrlHelpers

  plug :accepts, ~w(json)
  plug :authenticate
  plug :check_streaming_enabled

  def show(conn, %{"id" => id}) do
    conn.assigns.current_user
    |> Streaming.fetch_stream(id)
    |> stream_json(conn, id)
  end

  # TODO: remove after the release of the final CLI 3.0
  def show(conn, _params) do
    conn.assigns.current_user
    |> Streaming.fetch_default_stream()
    |> stream_json(conn, "default")
  end

  def create(conn, _params) do
    conn.assigns.current_user
    |> create_stream()
    |> stream_json(conn)
  end

  defp create_stream(user) do
    with {:error, :limit_reached} <- Streaming.create_stream(user) do
      Streaming.fetch_default_stream(user)
    end
  end

  defp stream_json(result, conn, id \\ nil)

  defp stream_json({:ok, stream}, conn, _id) do
    json(conn, %{
      url: url(~p"/s/#{stream}"),
      ws_producer_url: UrlHelpers.ws_producer_url(stream)
    })
  end

  defp stream_json({:error, :not_found}, conn, id) do
    conn
    |> put_status(404)
    |> json(%{reason: "stream #{id} not found"})
  end

  defp stream_json({:error, :too_many}, conn, _id) do
    conn
    |> put_status(422)
    |> json(%{reason: "no default stream found"})
  end

  defp authenticate(conn, _opts) do
    with {_username, cli} <- get_basic_auth(conn),
         {:ok, token} <- Accounts.fetch_cli(cli),
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

  defp check_streaming_enabled(conn, _opts) do
    if conn.assigns.current_user.streaming_enabled do
      conn
    else
      conn
      |> put_status(403)
      |> json(%{reason: "streaming disabled"})
      |> halt()
    end
  end
end
