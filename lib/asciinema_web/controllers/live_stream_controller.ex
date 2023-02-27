defmodule AsciinemaWeb.LiveStreamController do
  use AsciinemaWeb, :controller

  plug :clear_main_class

  def show(conn, params) do
    live_stream = %{
      cols: 80,
      cols_override: nil,
      rows: 24,
      rows_override: nil,
      theme_name: nil,
      user: %{id: 1, email: nil, username: nil, temporary_username: nil, theme_name: nil},
      snapshot: nil,
      idle_time_limit: nil,
      title: nil,
      command: nil,
      private: nil,
      id: params["id"]
    }

    conn
    |> assign(:live_stream, live_stream)
    |> render("show.html")
  end
end
