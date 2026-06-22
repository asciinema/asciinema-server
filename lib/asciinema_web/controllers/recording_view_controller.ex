defmodule AsciinemaWeb.RecordingViewController do
  use AsciinemaWeb, :controller
  alias Asciinema.Recordings

  @cookie_max_age 3600 * 24

  def create(conn, %{"recording_id" => id, "token" => token}) do
    with {:ok, real_id} <- Recordings.verify_view_count_token(token),
         %{id: ^real_id} = asciicast <- Recordings.lookup_asciicast(id),
         key = "a#{asciicast.id}",
         nil <- conn.req_cookies[key] do
      Recordings.register_view(asciicast)
      put_resp_cookie(conn, key, "1", max_age: @cookie_max_age)
    else
      _ -> conn
    end
    |> send_resp(204, "")
  end
end
