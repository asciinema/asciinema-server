defmodule AsciinemaWeb.FallbackController do
  use AsciinemaWeb, :controller

  def call(conn, {:error, :bad_request}), do: error(conn, 400)
  def call(conn, {:error, :forbidden}), do: error(conn, 403)
  def call(conn, {:error, :not_found}), do: error(conn, 404)

  defp error(conn, status) do
    conn =
      conn
      |> put_layout(:simple)
      |> put_status(status)

    case get_format(conn) do
      "html" ->
        conn
        |> put_view(AsciinemaWeb.ErrorHTML)
        |> render(:"#{status}")

      "json" ->
        conn
        |> put_view(AsciinemaWeb.ErrorJSON)
        |> render(:"#{status}")

      _ ->
        conn
        |> put_resp_content_type("text/plain")
        |> put_view(AsciinemaWeb.ErrorTEXT)
        |> render(:"#{status}")
    end
  end
end
