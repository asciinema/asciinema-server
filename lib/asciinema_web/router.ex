defmodule AsciinemaWeb.Router do
  use AsciinemaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AsciinemaWeb.Auth
    plug :assign_config
  end

  pipeline :asciicast do
    plug AsciinemaWeb.TrailingFormat
    plug :accepts, ["html", "js", "json", "cast", "txt", "svg", "png", "gif"]
    plug :format_specific_plugs
    plug :put_secure_browser_headers
  end

  defp assign_config(conn, []) do
    assign(conn, :cfg_sign_up_enabled?, Application.get_env(:asciinema, :sign_up_enabled?, true))
  end

  defp format_specific_plugs(conn, []) do
    format_specific_plugs(conn, Phoenix.Controller.get_format(conn))
  end

  defp format_specific_plugs(conn, "html") do
    conn
    |> fetch_session([])
    |> fetch_flash([])
    |> protect_from_forgery([])
    |> AsciinemaWeb.Auth.call([])
  end

  defp format_specific_plugs(conn, _other), do: conn

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

    get "/docs", DocController, :index
    get "/docs/:topic", DocController, :show

    resources "/login", LoginController, only: [:new, :create], singleton: true
    get "/login/sent", LoginController, :sent, as: :login

    resources "/user", UserController, as: :user, only: [:edit, :update], singleton: true
    resources "/users", UserController, as: :users, only: [:new, :create]
    get "/u/:id", UserController, :show
    get "/~:username", UserController, :show

    resources "/username", UsernameController, only: [:new, :create], singleton: true
    get "/username/skip", UsernameController, :skip, as: :username

    resources "/session", SessionController, only: [:new, :create, :delete], singleton: true

    get "/connect/:api_token", ApiTokenController, :show, as: :connect

    resources "/api_tokens", ApiTokenController, only: [:delete]
  end

  scope "/api", AsciinemaWeb.Api, as: :api do
    post "/asciicasts", RecordingController, :create
  end

  scope "/dev" do
    if Application.compile_env(:asciinema, :dev_routes) do
      forward "/mailbox", Bamboo.SentEmailViewerPlug
    end
  end
end

defmodule AsciinemaWeb.Router.Helpers.Extra do
  alias AsciinemaWeb.Router.Helpers, as: H
  alias AsciinemaWeb.Endpoint

  def root_path do
    Endpoint.path("/")
  end

  def root_url do
    Endpoint.url()
  end

  def profile_path(_conn, user) do
    profile_path(user)
  end

  def profile_path(%Plug.Conn{} = conn) do
    profile_path(conn.assigns.current_user)
  end

  def profile_path(%{id: id, username: username}) do
    if username do
      Endpoint.path("/~#{username}")
    else
      Endpoint.path("/u/#{id}")
    end
  end

  def profile_url(user) do
    Endpoint.url() <> profile_path(user)
  end

  def asciicast_file_path(conn, asciicast) do
    H.recording_path(conn, :show, asciicast) <> "." <> ext(asciicast)
  end

  def asciicast_file_url(asciicast) do
    asciicast_file_url(AsciinemaWeb.Endpoint, asciicast)
  end

  def asciicast_file_url(conn, asciicast) do
    H.recording_url(conn, :show, asciicast) <> "." <> ext(asciicast)
  end

  defp ext(asciicast) do
    case asciicast.version do
      0 -> "json"
      1 -> "json"
      _ -> "cast"
    end
  end
end
