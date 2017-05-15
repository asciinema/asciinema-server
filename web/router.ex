defmodule Asciinema.Router do
  use Asciinema.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Asciinema.Auth
  end

  pipeline :asciicast_animation do
    plug :accepts, ["html"]
  end

  scope "/", Asciinema do
    pipe_through :asciicast_animation

    # rewritten by TrailingFormat from /a/123.gif to /a/123/gif
    get "/a/:id/gif", AsciicastAnimationController, :show
  end

  scope "/", Asciinema do
    pipe_through :browser # Use the default browser stack

    get "/a/:id", AsciicastController, :show

    get "/docs", DocController, :index
    get "/docs/:topic", DocController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", Asciinema do
  #   pipe_through :api
  # end
end
