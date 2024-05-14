defmodule AsciinemaWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :asciinema

  @session_opts Application.compile_env!(:asciinema, :session_opts)

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_opts]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :asciinema,
    gzip: true,
    only: AsciinemaWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :asciinema
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, AsciinemaWeb.Plug.Parsers.MULTIPART, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug RemoteIp
  plug Sentry.PlugContext
  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_opts
  plug AsciinemaWeb.PlugAttack
  plug AsciinemaWeb.Router
end
