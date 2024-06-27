defmodule AsciinemaWeb.Api.RecordingController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Recordings, Accounts}

  plug :accepts, ~w(text json)
  plug :authenticate

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

  defp authenticate(conn, _opts) do
    with {username, api_token} <- get_basic_auth(conn),
         {:ok, user} <- Accounts.get_user_with_api_token(api_token, username) do
      conn
      |> assign(:install_id, api_token)
      |> assign(:current_user, user)
    else
      _otherwise ->
        conn
        |> send_resp(401, "Invalid or revoked recorder token")
        |> halt()
    end
  end
end
