defmodule AsciinemaWeb.Admin.Endpoint do
  use Phoenix.Endpoint, otp_app: :asciinema

  @session_options [
    store: :cookie,
    key: "_asciinema_admin_key",
    signing_salt: "qJL+3s0T",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug AsciinemaWeb.Admin.Router
end
