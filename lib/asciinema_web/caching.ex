defmodule AsciinemaWeb.Caching do
  import Plug.Conn

  def put_etag(conn, content) do
    etag = Crypto.md5(to_string(content))

    conn
    |> put_resp_header("etag", etag)
    |> register_before_send(fn conn ->
      if etag in get_req_header(conn, "if-none-match") do
        resp(conn, 304, "")
      else
        conn
      end
    end)
  end
end
