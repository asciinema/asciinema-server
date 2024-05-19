defmodule AsciinemaWeb.FallbackController do
  use AsciinemaWeb, :controller

  def call(conn, {:error, :bad_request}), do: error(conn, 400)
  def call(conn, {:error, :forbidden}), do: error(conn, 403)
  def call(conn, {:error, :not_found}), do: error(conn, 404)

  defp error(conn, status) do
    conn
    |> put_layout(:simple)
    |> put_status(status)
    |> put_view(
      html: AsciinemaWeb.ErrorHTML,
      json: AsciinemaWeb.ErrorJSON,
      cast: AsciinemaWeb.ErrorJSON,
      js: AsciinemaWeb.ErrorTEXT,
      txt: AsciinemaWeb.ErrorTEXT,
      svg: AsciinemaWeb.ErrorTEXT,
      png: AsciinemaWeb.ErrorTEXT,
      gif: AsciinemaWeb.ErrorTEXT,
      xml: AsciinemaWeb.ErrorTEXT
    )
    |> render(:"#{status}")
  end
end
