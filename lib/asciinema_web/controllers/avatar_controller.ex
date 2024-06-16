defmodule AsciinemaWeb.AvatarController do
  use AsciinemaWeb, :controller
  alias Asciinema.Accounts

  @one_day 24 * 60 * 60

  def show(conn, %{"id" => id}) do
    with {:ok, user} <- Accounts.fetch_user(id) do
      conn
      |> put_resp_header("cache-control", "public, max-age=#{@one_day}")
      |> render("show.svg", user: user)
    end
  end
end
