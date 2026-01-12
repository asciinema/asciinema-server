defmodule AsciinemaWeb.RecordingViewController do
  use AsciinemaWeb, :controller
  alias Asciinema.Recordings

  @cookie_max_age 3600 * 24

  def create(conn, %{"recording_id" => id, "token" => token}) do
    with {:ok, real_id} <- Recordings.verify_view_count_token(token),
         {:ok, asciicast} <- fetch_asciicast(id, real_id),
         key = "a#{asciicast.id}",
         nil <- conn.req_cookies[key] do
      Recordings.register_view(asciicast)

      conn
      |> put_resp_cookie(key, "1", max_age: @cookie_max_age)
      |> send_resp(204, "")
    else
      {:error, :invalid} ->
        send_resp(conn, 400, "")

      _ ->
        send_resp(conn, 204, "")
    end
  end

  defp fetch_asciicast(id, real_id) do
    with %{id: ^real_id} = asciicast <- Recordings.lookup_asciicast(id) do
      {:ok, asciicast}
    else
      _ -> {:error, :invalid}
    end
  end
end
