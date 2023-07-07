defmodule AsciinemaWeb.LiveStreamController do
  use AsciinemaWeb, :controller
  alias Asciinema.Streaming
  alias AsciinemaWeb.PlayerOpts

  plug :clear_main_class

  def show(conn, %{"id" => id}) do
    with {:ok, stream} <- Streaming.fetch_live_stream(id) do
      do_show(conn, stream)
    end
  end

  defp do_show(conn, stream) do
    render(conn, stream: stream, player_opts: player_opts(conn.params))
  end

  defp player_opts(params) do
    PlayerOpts.parse(params, :live_stream)
  end
end
