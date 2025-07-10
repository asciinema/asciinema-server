defmodule AsciinemaWeb.Router do
  use AsciinemaWeb, :router
  alias AsciinemaWeb.Plug.{Authn, TrailingFormat}

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Authn
  end

  pipeline :api do
    plug :accepts, ~w(json)
  end

  pipeline :asciicast do
    plug TrailingFormat
    plug :accepts, ~w(html js json cast txt svg png gif)
    plug :format_specific_plugs
    plug :put_secure_browser_headers
  end

  pipeline :oembed do
    plug :accepts, ~w(json xml)
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

    resources "/s", StreamController, only: [:show, :edit, :update, :delete]

    resources "/login", LoginController, only: [:new, :create], singleton: true
    get "/login/sent", LoginController, :sent, as: :login

    resources "/user", UserController,
      as: :user,
      only: [:edit, :update, :delete],
      singleton: true do
      resources "/streams", StreamController, only: [:index, :create]
    end

    resources "/users", UserController, as: :users, only: [:new, :create]
    get "/u/:id", UserController, :show
    get "/~:username", UserController, :show
    get "/u/:id/avatar", AvatarController, :show
    get "/user/delete", UserController, :delete, as: :user_deletion

    resources "/username", UsernameController, only: [:new, :create], singleton: true
    get "/username/skip", UsernameController, :skip, as: :username

    resources "/session", SessionController, only: [:new, :create, :delete], singleton: true

    get "/connect/:install_id", CliController, :register, as: :connect

    resources "/clis", CliController, only: [:delete]

    get "/about", PageController, :about
  end

  scope "/api", AsciinemaWeb.Api, as: :api do
    pipe_through :api

    scope "/v1" do
      resources "/recordings", RecordingController, only: [:create, :update, :delete]
      resources "/streams", StreamController, only: [:create, :update, :delete]

      scope "/user" do
        get "/streams", StreamController, :index
      end
    end

    # legacy endpoints

    # used by CLI 2.x
    post "/asciicasts", RecordingController, :create

    # used by CLI 3.0 RC.5 and earlier
    post "/streams", StreamController, :create

    # used by CLI 3.0 RC.5 and earlier
    scope "/user" do
      get "/streams/:id", StreamController, :show
    end
  end

  if Application.compile_env(:asciinema, :dev_routes) do
    scope "/dev" do
      pipe_through :browser
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  defp format_specific_plugs(conn, []) do
    conn
    |> fetch_session([])
    |> Authn.call([])
    |> format_specific_plugs(get_format(conn))
  end

  defp format_specific_plugs(conn, "html") do
    conn
    |> fetch_flash([])
    |> protect_from_forgery([])
  end

  defp format_specific_plugs(conn, _other), do: conn
end
