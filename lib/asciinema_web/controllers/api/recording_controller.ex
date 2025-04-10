defmodule AsciinemaWeb.Api.RecordingController do
  use AsciinemaWeb, :controller
  use Asciinema.Config
  alias Asciinema.{Recordings, Accounts}

  plug :accepts, ~w(text json)
  plug :assign_install_id
  plug :assign_cli

  def create(conn, %{"asciicast" => %Plug.Upload{} = upload}) do
    cli = conn.assigns.cli
    user_agent = conn |> get_req_header("user-agent") |> List.first()

    case Recordings.create_asciicast(cli.user, upload, %{cli_id: cli.id, user_agent: user_agent}) do
      {:ok, asciicast} ->
        url = url(~p"/a/#{asciicast}")

        conn
        |> put_status(:created)
        |> put_resp_header("location", url)
        |> render(:created, url: url, install_id: conn.assigns.install_id)

      {:error, :unknown_format} ->
        conn
        |> put_status(:bad_request)
        |> text("This doesn't look like a valid asciicast file")

      {:error, {:invalid_version, version}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> text("asciicast v#{version} format is not supported by this server")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end

  defp assign_install_id(conn, _opts) do
    case get_basic_auth(conn) do
      {username, install_id} ->
        conn
        |> assign(:install_id, install_id)
        |> assign(:username, username)

      _otherwise ->
        conn
        |> put_status(401)
        |> text(error_message(:token_missing))
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
        |> put_status(401)
        |> text(error_message(reason))
        |> halt()
    end
  end

  defp error_message(:token_missing), do: "Missing install ID"
  defp error_message(:token_not_found), do: "Unregistered install ID"
  defp error_message(:token_invalid), do: "Invalid install ID"
  defp error_message(:cli_revoked), do: "Revoked install ID"
end
