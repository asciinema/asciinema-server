defmodule AsciinemaWeb.LiveStreamController do
  use AsciinemaWeb, :controller
  alias Asciinema.Streaming

  plug :clear_main_class

  def show(conn, %{"id" => id}) do
    with {:ok, stream} <- Streaming.fetch_live_stream(id) do
      do_show(conn, stream)
    end
  end

  defp do_show(conn, stream) do
    conn
    |> assign(:stream, stream)
    |> render(:show)
  end
end
