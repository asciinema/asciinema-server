defmodule AsciinemaWeb.Api.RecordingController do
  use AsciinemaWeb, :controller
  use Asciinema.Config
  alias Asciinema.{Recordings, Accounts}

  plug :accepts, ~w(text json)
  plug :assign_install_id
  plug :assign_current_user

  def create(conn, %{"asciicast" => %Plug.Upload{} = upload}) do
    user = conn.assigns.current_user
    user_agent = conn |> get_req_header("user-agent") |> List.first()

    case Recordings.create_asciicast(user, upload, %{user_agent: user_agent}) do
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

      {:error, {:unsupported_format, version}} ->
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

  defp assign_current_user(conn, _opts) do
    with {:ok, user} <- authenticate(conn) do
      assign(conn, :current_user, user)
    else
      {:error, reason} ->
        conn
        |> put_status(401)
        |> text(error_message(reason))
        |> halt()
    end
  end

  defp authenticate(conn) do
    %{install_id: install_id, username: username} = conn.assigns

    with {:ok, cli} <- Accounts.fetch_cli(install_id) do
      {:ok, cli.user}
    else
      {:error, :cli_revoked} = result ->
        result

      {:error, :token_not_found} = result ->
        if config(:upload_auth_required, false) do
          result
        else
          Accounts.create_user_with_cli(install_id, username)
        end
    end
  end

  defp error_message(:token_missing), do: "Missing recorder token"
  defp error_message(:token_not_found), do: "Unregistered recorder token"
  defp error_message(:token_invalid), do: "Invalid recorder token"
  defp error_message(:cli_revoked), do: "Revoked recorder token"
end
