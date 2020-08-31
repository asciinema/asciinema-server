use Mix.Config

# Configure your database
config :asciinema, Asciinema.Repo,
  username: "postgres",
  password: "postgres",
  database: "asciinema_development",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
  "60BnXnzGGwwiZj91YA9XYKF9BCiM7lQ/1um8VXcWWLSdUp9OcPZV6YnQv7eFTYSY"

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :asciinema, AsciinemaWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  secret_key_base: secret_key_base,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :asciinema, Asciinema.Accounts, secret: secret_key_base

# Watch static and templates for browser reloading.
config :asciinema, AsciinemaWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/asciinema_web/views/.*(ex)$",
      ~r"lib/asciinema_web/templates/.*(eex|md)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :asciinema, Asciinema.Emails.Mailer,
  adapter: Bamboo.LocalAdapter

if gc_days = System.get_env("ASCIICAST_GC_DAYS") do
  config :asciinema, :asciicast_gc_days, String.to_integer(gc_days)
end

# Import custom config.
import_config "custom*.exs"
