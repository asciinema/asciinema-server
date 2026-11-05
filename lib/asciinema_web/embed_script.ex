defmodule AsciinemaWeb.EmbedScript do
  import Plug.Conn

  @max_age 60

  def send(conn) do
    path = Application.app_dir(:asciinema, "priv/static/js/embed.js")

    conn
    |> put_resp_content_type("application/javascript")
    |> put_resp_header("cache-control", "public, max-age=#{@max_age}")
    |> send_file(200, path)
  end
end
