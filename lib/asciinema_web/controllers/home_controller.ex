defmodule AsciinemaWeb.HomeController do
  use AsciinemaWeb, :controller
  alias Asciinema.Recordings

  def show(conn, _params) do
    asciicast =
      if id = Application.get_env(:asciinema, :home_asciicast_id) do
        Recordings.get_asciicast(id)
      else
        :public
        |> Recordings.query()
        |> Recordings.list(1)
        |> List.first()
      end

    asciicasts =
      [:featured, :from_last_2_years]
      |> Recordings.query(:random)
      |> Recordings.list(6)

    render(
      conn,
      :show,
      asciicast: asciicast,
      asciicasts: asciicasts
    )
  end
end
