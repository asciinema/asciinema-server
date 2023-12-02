defmodule AsciinemaWeb.Admin.Router do
  use AsciinemaWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", AsciinemaWeb.Admin do
    pipe_through :browser

    live_dashboard "/dashboard", metrics: Asciinema.Telemetry
  end
end
