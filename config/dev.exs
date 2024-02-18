import Config

# Configure your database
config :asciinema, Asciinema.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "asciinema_development",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

secret_key_base = "60BnXnzGGwwiZj91YA9XYKF9BCiM7lQ/1um8VXcWWLSdUp9OcPZV6YnQv7eFTYSY"

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :asciinema, AsciinemaWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: secret_key_base,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch",
      "--watch-options-stdin",
      cd: Path.expand("../assets", __DIR__),
      env: [{"NODE_OPTIONS", "--openssl-legacy-provider"}]
    ]
  ]

config :asciinema, AsciinemaWeb.Admin.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: secret_key_base

config :asciinema, Asciinema.Accounts, secret: secret_key_base

# Watch static and templates for browser reloading.
config :asciinema, AsciinemaWeb.Endpoint,
  live_reload: [
    interval: 1000,
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/asciinema_web/views/.*(ex)$",
      ~r"lib/asciinema_web/templates/.*(eex|md)$",
      ~r"lib/asciinema_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :asciinema, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :asciinema, Asciinema.Telemetry, enabled: false

# Import custom config.
for config <- "custom*.exs" |> Path.expand(__DIR__) |> Path.wildcard() do
  import_config config
end
