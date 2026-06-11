defmodule AsciinemaAdmin.Router do
  use AsciinemaAdmin, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/", AsciinemaAdmin do
    pipe_through :browser

    get "/", PlaceholderController, :show
  end
end
