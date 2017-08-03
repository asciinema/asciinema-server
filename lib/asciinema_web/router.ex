defmodule AsciinemaWeb.Router do
  use AsciinemaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AsciinemaWeb.Auth
  end

  pipeline :asciicast_embed_script do
    plug :accepts, ["js"]
  end

  scope "/", AsciinemaWeb do
    pipe_through :asciicast_embed_script

    # rewritten by TrailingFormat from /a/123.js to /a/123/js
    get "/a/:id/js", AsciicastEmbedController, :show
  end

  pipeline :asciicast_file do
    plug :accepts, ["json"]
  end

  scope "/", AsciinemaWeb do
    pipe_through :asciicast_file

    # rewritten by TrailingFormat from /a/123.json to /a/123/json
    get "/a/:id/json", AsciicastFileController, :show
  end

  pipeline :asciicast_image do
    plug :accepts, ["png"]
  end

  scope "/", AsciinemaWeb do
    pipe_through :asciicast_image

    # rewritten by TrailingFormat from /a/123.png to /a/123/png
    get "/a/:id/png", AsciicastImageController, :show
  end

  pipeline :asciicast_animation do
    plug :accepts, ["html"]
  end

  scope "/", AsciinemaWeb do
    pipe_through :asciicast_animation

    # rewritten by TrailingFormat from /a/123.gif to /a/123/gif
    get "/a/:id/gif", AsciicastAnimationController, :show
  end

  scope "/", AsciinemaWeb do
    pipe_through :browser # Use the default browser stack

    get "/a/:id", AsciicastController, :show

    get "/docs", DocController, :index
    get "/docs/:topic", DocController, :show

    resources "/login", LoginController, only: [:new, :create], singleton: true
    get "/login/sent", LoginController, :sent, as: :login

    resources "/users", UserController, as: :users, only: [:new, :create]

    resources "/session", SessionController, only: [:new, :create], singleton: true
    get "/connect/:api_token", SessionController, :create, as: :connect
  end

  scope "/api", AsciinemaWeb.Api, as: :api do
    post "/asciicasts", AsciicastController, :create
  end

  # Other scopes may use custom stacks.
  # scope "/api", Asciinema do
  #   pipe_through :api
  # end
end

defmodule AsciinemaWeb.Router.Helpers.Extra do
  alias AsciinemaWeb.Router.Helpers, as: H

  def user_path(_conn, :edit) do
    "/user/edit"
  end

  def asciicast_file_download_path(conn, asciicast) do
    conn
    |> H.asciicast_file_path(:show, asciicast)
    |> String.replace_suffix("/json", ".json")
  end

  def asciicast_file_download_url(conn, asciicast) do
    conn
    |> H.asciicast_file_url(:show, asciicast)
    |> String.replace_suffix("/json", ".json")
  end

  def asciicast_image_download_path(conn, asciicast) do
    conn
    |> H.asciicast_image_path(:show, asciicast)
    |> String.replace_suffix("/png", ".png")
  end

  def asciicast_animation_download_path(conn, asciicast) do
    conn
    |> H.asciicast_animation_path(:show, asciicast)
    |> String.replace_suffix("/gif", ".gif")
  end
end
