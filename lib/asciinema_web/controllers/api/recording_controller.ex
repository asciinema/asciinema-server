defmodule AsciinemaWeb.Api.RecordingController do
  use AsciinemaWeb, :controller
  use Asciinema.Config
  alias Asciinema.{Recordings, Accounts}

  plug :assign_install_id
  plug :assign_cli
  plug :require_registered_cli when action in [:update, :delete]
  plug :load_asciicast when action in [:update, :delete]
  plug :authorize, :asciicast when action in [:update, :delete]

  def create(conn, %{"asciicast" => %Plug.Upload{} = upload}), do: create(conn, upload)
  def create(conn, %{"file" => %Plug.Upload{} = upload}), do: create(conn, upload)

  def create(conn, upload) do
    cli = conn.assigns.cli
    user_agent = get_user_agent(conn)

    case Recordings.create_asciicast(cli.user, upload, %{cli_id: cli.id, user_agent: user_agent}) do
      {:ok, asciicast} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", url(~p"/a/#{asciicast}"))
        |> render(:show, asciicast: asciicast)

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, reason: reason)
    end
  end

  def update(conn, params) do
    asciicast = conn.assigns.asciicast

    case Recordings.update_asciicast(asciicast, params) do
      {:ok, asciicast} ->
        render(conn, :show, asciicast: asciicast)

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, reason: reason)
    end
  end

  def delete(conn, _params) do
    asciicast = conn.assigns.asciicast
    {:ok, _} = Recordings.delete_asciicast(asciicast)

    conn
    |> put_status(:no_content)
    |> render(:deleted)
  end

  defp get_user_agent(conn) do
    conn
    |> get_req_header("user-agent")
    |> List.first()
  end

  defp assign_install_id(conn, _opts) do
    case get_basic_auth(conn) do
      {username, install_id} ->
        conn
        |> assign(:install_id, install_id)
        |> assign(:username, username)

      _otherwise ->
        conn
        |> put_status(:unauthorized)
        |> render(:error, reason: :token_missing)
        |> halt()
    end
  end

  defp assign_cli(conn, _opts) do
    %{install_id: install_id, username: username} = conn.assigns

    with {:ok, cli} <- Accounts.register_cli(username, install_id) do
      conn
      |> assign(:cli, cli)
      |> assign(:current_user, cli.user)
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> render(:error, reason: reason)
        |> halt()
    end
  end

  defp require_registered_cli(conn, _opts) do
    if Accounts.cli_registered?(conn.assigns.cli) do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, reason: :token_not_found)
      |> halt()
    end
  end

  defp load_asciicast(conn, _) do
    id = String.trim(conn.params["id"])

    if asciicast = Recordings.lookup_asciicast(id) do
      assign(conn, :asciicast, asciicast)
    else
      conn
      |> put_status(:not_found)
      |> render(:error, reason: :asciicast_not_found)
      |> halt()
    end
  end
end
