defmodule AsciinemaWeb.Router do
  use AsciinemaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AsciinemaWeb.Plug.Authn
  end

  pipeline :asciicast do
    plug AsciinemaWeb.Plug.TrailingFormat
    plug :accepts, ["html", "js", "json", "cast", "txt", "svg", "png", "gif"]
    plug :format_specific_plugs
    plug :put_secure_browser_headers
  end

  pipeline :oembed do
    plug :accepts, ["json", "xml"]
    plug :put_secure_browser_headers
  end

  pipeline :webfinger do
    plug :put_format, :json
  end

  scope "/", AsciinemaWeb do
    pipe_through :asciicast

    resources "/a", RecordingController, only: [:show, :edit, :update, :delete]
  end

  scope "/", AsciinemaWeb do
    pipe_through :oembed

    get "/oembed", OembedController, :show
  end

  scope "/", AsciinemaWeb do
    pipe_through :webfinger
    get "/.well-known/webfinger", WebFingerController, :show
  end

  scope "/", AsciinemaWeb do
    # Use the default browser stack
    pipe_through :browser

    get "/", RecordingController, :auto

    get "/explore", RecordingController, :auto, as: :explore
    get "/explore/featured", RecordingController, :featured, as: :explore
    get "/explore/public", RecordingController, :public, as: :explore

    get "/a/:id/iframe", RecordingController, :iframe
    get "/a/:id/example", RecordingController, :example

    resources "/s", LiveStreamController, only: [:show, :edit, :update]

    resources "/login", LoginController, only: [:new, :create], singleton: true
    get "/login/sent", LoginController, :sent, as: :login

    resources "/user", UserController, as: :user, only: [:edit, :update, :delete], singleton: true
    resources "/users", UserController, as: :users, only: [:new, :create]
    get "/u/:id", UserController, :show
    get "/~:username", UserController, :show
    get "/u/:id/avatar", AvatarController, :show
    get "/user/delete", UserController, :delete, as: :user_deletion

    resources "/username", UsernameController, only: [:new, :create], singleton: true
    get "/username/skip", UsernameController, :skip, as: :username

    resources "/session", SessionController, only: [:new, :create, :delete], singleton: true

    get "/connect/:api_token", ApiTokenController, :register, as: :connect

    resources "/api_tokens", ApiTokenController, only: [:delete]

    get "/about", PageController, :about
  end

  scope "/api", AsciinemaWeb.Api, as: :api do
    post "/asciicasts", RecordingController, :create
    post "/streams", LiveStreamController, :create

    scope "/user" do
      get "/stream", LiveStreamController, :show
      get "/streams/:id", LiveStreamController, :show
    end
  end

  if Application.compile_env(:asciinema, :dev_routes) do
    scope "/dev" do
      pipe_through :browser
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  defp format_specific_plugs(conn, []) do
    format_specific_plugs(conn, Phoenix.Controller.get_format(conn))
  end

  defp format_specific_plugs(conn, "html") do
    conn
    |> fetch_session([])
    |> fetch_flash([])
    |> protect_from_forgery([])
    |> AsciinemaWeb.Plug.Authn.call([])
  end

  defp format_specific_plugs(conn, _other), do: conn
end
