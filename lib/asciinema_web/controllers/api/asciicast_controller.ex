defmodule AsciinemaWeb.Api.AsciicastController do
  use AsciinemaWeb, :controller
  import AsciinemaWeb.Auth, only: [get_basic_auth: 1, put_basic_auth: 3]
  alias Asciinema.{Asciicasts, Accounts}
  alias Asciinema.Accounts.User

  plug :parse_v0_params
  plug :authenticate

  def create(conn, %{"asciicast" => %Plug.Upload{} = upload}) do
    do_create(conn, upload)
  end
  def create(conn, %{"asciicast" => %{"meta" => %{},
                                      "stdout" => %Plug.Upload{},
                                      "stdout_timing" => %Plug.Upload{}} = asciicast_params}) do
    do_create(conn, asciicast_params)
  end

  defp do_create(conn, params) do
    user = conn.assigns.current_user
    user_agent = conn |> get_req_header("user-agent") |> List.first

    case Asciicasts.create_asciicast(user, params, %{user_agent: user_agent}) do
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

  defp parse_v0_params(%Plug.Conn{params: %{"asciicast" => %{"meta" => %Plug.Upload{path: meta_path}}}} = conn, _) do
    with {:ok, json} <- File.read(meta_path),
         {:ok, attrs} <- Poison.decode(json) do
      conn
      |> put_param(["asciicast", "meta"], Map.put(attrs, "version", 0))
      |> put_basic_auth(attrs["username"], attrs["user_token"])
    else
      {:error, :invalid} ->
        send_resp(conn, 400, "")
    end
  end
  defp parse_v0_params(conn, _), do: conn

  defp put_param(%Plug.Conn{params: params} = conn, path, value) do
    params = put_in(params, path, value)
    %{conn | params: params}
  end

  defp authenticate(conn, _opts) do
    with {username, api_token} <- get_basic_auth(conn),
         {:ok, %User{} = user} <- Accounts.get_user_with_api_token(api_token, username) do
      assign(conn, :current_user, user)
    else
      _otherwise ->
        conn
        |> send_resp(401, "Invalid or revoked recorder token")
        |> halt()
    end
  end
end
