defmodule Asciinema.Api.AsciicastController do
  use Asciinema.Web, :controller
  import Asciinema.Auth, only: [get_basic_auth: 1]
  alias Asciinema.{Asciicasts, Users, User}

  plug :authenticate

  def create(conn, %{"asciicast" => %Plug.Upload{} = upload}) do
    user = conn.assigns.current_user

    case Asciicasts.create_asciicast(user, upload) do
      {:ok, asciicast} ->
        url = asciicast_url(conn, :show, asciicast)
        conn
        |> put_status(:created)
        |> put_resp_header("location", url)
        |> text(url)
      {:error, :parse_error} ->
        conn
        |> put_status(:bad_request)
        |> text("This doesn't look like a valid asciicast file")
      {:error, :unknown_format} ->
        conn
        |> put_status(:unsupported_media_type)
        |> text("Format not supported")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end

  defp authenticate(conn, _opts) do
    with {username, api_token} <- get_basic_auth(conn),
         %User{} = user <- Users.get_user_with_api_token(username, api_token) do
      assign(conn, :current_user, user)
    else
      _otherwise ->
        conn
        |> send_resp(401, "Invalid or revoked recorder token")
        |> halt()
    end
  end
end
