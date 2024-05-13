defmodule AsciinemaWeb.FallbackController do
  use Phoenix.Controller, namespace: AsciinemaWeb

  def call(conn, {:error, :bad_request}), do: error(conn, 400)
  def call(conn, {:error, :forbidden}), do: error(conn, 403)
  def call(conn, {:error, :not_found}), do: error(conn, 404)

  defp error(conn, status) do
    conn
    |> put_layout(:simple)
    |> put_view(AsciinemaWeb.ErrorView)
    |> put_status(status)
    |> render(:"#{status}")
  end
end
