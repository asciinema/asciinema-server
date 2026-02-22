defmodule AsciinemaWeb.Caching do
  import Plug.Conn

  def put_etag(conn, content) do
    put_resp_header(conn, "etag", etag(content))
  end

  def fresh?(conn) do
    case get_resp_header(conn, "etag") do
      [etag] ->
        etag = normalize_etag(etag)

        Enum.any?(get_req_header(conn, "if-none-match"), fn header ->
          Enum.any?(String.split(header, ","), fn value ->
            value = String.trim(value)
            value == "*" or normalize_etag(value) == etag
          end)
        end)

      _ ->
        false
    end
  end

  defp etag(content) do
    ~s("#{Crypto.md5(to_string(content))}")
  end

  defp normalize_etag(value) do
    value
    |> String.trim()
    |> String.trim_leading("W/")
  end
end
