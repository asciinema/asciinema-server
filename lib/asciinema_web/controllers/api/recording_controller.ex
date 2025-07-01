defmodule AsciinemaWeb.Api.RecordingController do
  use AsciinemaWeb, :controller
  use Asciinema.Config
  alias Asciinema.{Recordings, Accounts}

  plug :assign_install_id
  plug :assign_cli

  def create(conn, %{"asciicast" => %Plug.Upload{} = upload}) do
    cli = conn.assigns.cli
    user_agent = get_user_agent(conn)

    case Recordings.create_asciicast(cli.user, upload, %{cli_id: cli.id, user_agent: user_agent}) do
      {:ok, asciicast} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", url(~p"/a/#{asciicast}"))
        |> render(:created, asciicast: asciicast)

      {:error, :invalid_format} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, reason: :invalid_recording_format)

      {:error, {:invalid_version, version}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, reason: {:invalid_asciicast_version, version})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
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
      assign(conn, :cli, cli)
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> render(:error, reason: reason)
        |> halt()
    end
  end
end
