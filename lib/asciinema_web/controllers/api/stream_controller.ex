defmodule AsciinemaWeb.Api.StreamController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Accounts, Streaming}

  plug :authenticate
  plug :check_streaming_enabled
  plug :load_stream when action in [:update, :delete]
  plug :authorize, :stream when action in [:update, :delete]

  def show(conn, %{"id" => id}) do
    conn.assigns.current_user
    |> Streaming.fetch_stream(id)
    |> render_stream(conn, id)
  end

  # TODO: remove after the release of the final CLI 3.0
  def show(conn, _params) do
    conn.assigns.current_user
    |> Streaming.fetch_default_stream()
    |> render_stream(conn, "default")
  end

  def create(conn, _params) do
    conn.assigns.current_user
    |> create_stream()
    |> render_stream(conn)
  end

  def update(conn, params) do
    case Streaming.update_stream(conn.assigns.stream, params) do
      {:ok, stream} ->
        render(conn, :show, stream: stream)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, reason: changeset)
    end
  end

  def delete(conn, _params) do
    {:ok, _} = Streaming.delete_stream(conn.assigns.stream)

    conn
    |> put_status(:no_content)
    |> render(:deleted)
  end

  defp create_stream(user) do
    with {:error, :limit_reached} <- Streaming.create_stream(user) do
      Streaming.fetch_default_stream(user)
    end
  end

  defp render_stream(result, conn, id \\ nil)

  defp render_stream({:ok, stream}, conn, _id) do
    render(conn, :show, stream: stream)
  end

  defp render_stream({:error, :not_found}, conn, id) do
    conn
    |> put_status(:not_found)
    |> render(:error, reason: "stream #{id} not found")
  end

  defp render_stream({:error, :too_many}, conn, _id) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(:error, reason: "no default stream found")
  end

  defp authenticate(conn, _opts) do
    with {_username, token} <- get_basic_auth(conn),
         {:ok, cli} <- Accounts.fetch_cli(token),
         true <- Accounts.cli_registered?(cli) do
      assign(conn, :current_user, cli.user)
    else
      _otherwise ->
        conn
        |> put_status(:unauthorized)
        |> json(%{})
        |> halt()
    end
  end

  defp check_streaming_enabled(conn, _opts) do
    if conn.assigns.current_user.streaming_enabled do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> render(:error, reason: "streaming disabled")
      |> halt()
    end
  end

  defp load_stream(conn, _opts) do
    case Streaming.get_stream(conn.params["id"]) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, reason: "stream not found")
        |> halt()

      stream ->
        assign(conn, :stream, stream)
    end
  end
end
