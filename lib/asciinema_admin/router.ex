defmodule AsciinemaAdmin.Router do
  use AsciinemaAdmin, :router
  import Oban.Web.Router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", AsciinemaAdmin do
    pipe_through :browser

    get "/", HomeController, :show
  end

  scope "/admin", AsciinemaAdmin do
    pipe_through :browser

    get "/", HomeController, :show
    get "/users/lookup", UserController, :lookup

    resources "/users", UserController do
      resources "/clis", CliController
    end

    live_dashboard "/dashboard", metrics: Asciinema.Telemetry
    oban_dashboard("/oban")
  end
end
