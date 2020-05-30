defmodule AsciinemaWeb.FallbackController do
  use Phoenix.Controller, namespace: AsciinemaWeb

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_layout(:simple)
    |> put_view(AsciinemaWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> put_layout(:simple)
    |> put_view(AsciinemaWeb.ErrorView)
    |> render(:"400")
  end
end
