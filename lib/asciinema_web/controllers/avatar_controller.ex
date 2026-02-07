defmodule AsciinemaWeb.AvatarController do
  use AsciinemaWeb, :controller
  alias Asciinema.Accounts

  @one_day 24 * 60 * 60

  def show(conn, %{"username" => username}) do
    result = Accounts.find_user_by_profile_id(username)

    with {:ok, user} <- OK.required(result, :not_found) do
      conn
      |> put_resp_header("cache-control", "public, max-age=#{@one_day}")
      |> render("show.svg", user: user)
    end
  end
end
