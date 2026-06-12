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

    resources "/saved_queries", SavedQueryController, only: [:create, :update, :delete]

    resources "/users", UserController
    get "/users/:id/merge", UserController, :merge_confirm
    post "/users/:id/merge", UserController, :merge

    post "/users/:user_id/clis", CliController, :create

    resources "/recordings", RecordingController, only: [:index, :show, :edit, :update, :delete]
    get "/recordings/:id/file", RecordingController, :cast_file
    post "/recordings/:id/visibility", RecordingController, :set_visibility
    post "/recordings/:id/featured", RecordingController, :set_featured
    post "/recordings/:id/archive_now", RecordingController, :archive_now
    post "/recordings/:id/unarchive", RecordingController, :unarchive

    resources "/streams", StreamController, only: [:index, :show, :edit, :update, :delete]
    post "/streams/:id/visibility", StreamController, :set_visibility
    post "/streams/:id/disconnect", StreamController, :disconnect

    live_dashboard "/system/dashboard", metrics: Asciinema.Telemetry
    oban_dashboard("/system/oban")
  end
end
