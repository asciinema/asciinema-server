defmodule AsciinemaAdmin.Router do
  use AsciinemaAdmin, :router
  import Oban.Web.Router
  import Phoenix.LiveDashboard.Router
  import AsciinemaAdmin.Plugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_current_path
  end

  scope "/", AsciinemaAdmin do
    pipe_through :browser

    get "/", RedirectController, :to_admin
  end

  scope "/admin", AsciinemaAdmin do
    pipe_through :browser

    get "/", HomeController, :show

    get "/users", UserController, :index
    get "/users/new", UserController, :new
    post "/users", UserController, :create
    get "/users/:id", UserController, :show
    get "/users/:id/edit", UserController, :edit
    put "/users/:id", UserController, :update
    delete "/users/:id", UserController, :delete
    get "/users/:id/merge", UserController, :merge_confirm
    post "/users/:id/merge", UserController, :merge

    post "/users/:user_id/clis", CliController, :create

    live_dashboard "/system/dashboard", metrics: Asciinema.Telemetry
    oban_dashboard("/system/oban")
  end
end
