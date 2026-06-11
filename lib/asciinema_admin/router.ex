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

    post "/saved_queries", SavedQueryController, :create
    put "/saved_queries/:id", SavedQueryController, :update
    delete "/saved_queries/:id", SavedQueryController, :delete

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

    get "/recordings", RecordingController, :index
    get "/recordings/:id", RecordingController, :show
    get "/recordings/:id/file", RecordingController, :cast_file
    get "/recordings/:id/edit", RecordingController, :edit
    put "/recordings/:id", RecordingController, :update
    delete "/recordings/:id", RecordingController, :delete
    post "/recordings/:id/visibility", RecordingController, :set_visibility
    post "/recordings/:id/featured", RecordingController, :set_featured
    post "/recordings/:id/archive_now", RecordingController, :archive_now
    post "/recordings/:id/unarchive", RecordingController, :unarchive

    get "/streams", StreamController, :index
    get "/streams/:id", StreamController, :show
    get "/streams/:id/edit", StreamController, :edit
    put "/streams/:id", StreamController, :update
    delete "/streams/:id", StreamController, :delete
    post "/streams/:id/visibility", StreamController, :set_visibility
    post "/streams/:id/disconnect", StreamController, :disconnect

    live_dashboard "/system/dashboard", metrics: Asciinema.Telemetry
    oban_dashboard("/system/oban")
  end
end
