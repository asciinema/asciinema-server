defmodule AsciinemaWeb.Router do
  use AsciinemaWeb, :router
  use Plug.ErrorHandler
  defp handle_errors(_conn, %{reason: %Ecto.NoResultsError{}}), do: nil
  defp handle_errors(_conn, %{reason: %Phoenix.NotAcceptableError{}}), do: nil
  use Sentry.Plug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AsciinemaWeb.Auth
  end

  pipeline :asciicast do
    plug :accepts, ["html", "js", "json", "cast", "png", "gif"]
    plug :format_specific_plugs
    plug :put_secure_browser_headers
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

  scope "/", AsciinemaWeb do
    pipe_through :asciicast

    resources "/a", AsciicastController, only: [:show, :edit, :update, :delete]
  end

  scope "/", AsciinemaWeb do
    pipe_through :oembed

    get "/oembed", OembedController, :show
  end

  scope "/", AsciinemaWeb do
    pipe_through :browser # Use the default browser stack

    get "/", HomeController, :show

    get "/explore", AsciicastController, :index
    get "/explore/:category", AsciicastController, :category

    get "/a/:id/iframe", AsciicastController, :iframe
    get "/a/:id/embed", AsciicastController, :embed
    get "/a/:id/example", AsciicastController, :example

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

    get "/about", PageController, :about
    get "/privacy", PageController, :privacy
    get "/tos", PageController, :tos
    get "/contact", PageController, :contact
    get "/contributing", PageController, :contributing
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
  alias AsciinemaWeb.Endpoint

  def profile_path(_conn, user) do
    profile_path(user)
  end

  def profile_path(%Plug.Conn{} = conn) do
    profile_path(conn.assigns.current_user)
  end

  def profile_path(%{id: id, username: username}) do
    if username do
      "/~#{username}"
    else
      "/u/#{id}"
    end
  end

  def profile_url(user) do
    Endpoint.url() <> profile_path(user)
  end

  def asciicast_file_path(conn, asciicast) do
    H.asciicast_path(conn, :show, asciicast) <> "." <> ext(asciicast)
  end

  def asciicast_file_url(asciicast) do
    asciicast_file_url(AsciinemaWeb.Endpoint, asciicast)
  end

  def asciicast_file_url(conn, asciicast) do
    H.asciicast_url(conn, :show, asciicast) <> "." <> ext(asciicast)
  end

  defp ext(asciicast) do
    case asciicast.version do
      0 -> "json"
      1 -> "json"
      _ -> "cast"
    end
  end

  def asciicast_image_path(conn, asciicast) do
    H.asciicast_path(conn, :show, asciicast) <> ".png"
  end

  def asciicast_image_url(conn, asciicast) do
    H.asciicast_url(conn, :show, asciicast) <> ".png"
  end

  def asciicast_animation_path(conn, asciicast) do
    H.asciicast_path(conn, :show, asciicast) <> ".gif"
  end

  def asciicast_script_url(conn, asciicast) do
    H.asciicast_path(conn, :show, asciicast) <> ".js"
  end
end
