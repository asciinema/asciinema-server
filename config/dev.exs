use Mix.Config

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
  secret_key_base: System.get_env("SECRET_KEY_BASE") || "60BnXnzGGwwiZj91YA9XYKF9BCiM7lQ/1um8VXcWWLSdUp9OcPZV6YnQv7eFTYSY",
  watchers: [node: ["node_modules/webpack/bin/webpack.js", "--mode", "development", "--watch-stdin",
                    cd: Path.expand("../assets", __DIR__)]]


# Watch static and templates for browser reloading.
config :asciinema, AsciinemaWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/asciinema_web/views/.*(ex)$},
      ~r{lib/asciinema_web/templates/.*(eex|md)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :asciinema, Asciinema.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "asciinema_development",
  hostname: "localhost",
  pool_size: 10

config :asciinema, Asciinema.Mailer,
  adapter: Bamboo.LocalAdapter

config :asciinema, Asciinema.Vt.Worker,
  vt_script_path: "vt/main.js"

if gc_days = System.get_env("ASCIICAST_GC_DAYS") do
  config :asciinema, :asciicast_gc_days, String.to_integer(gc_days)
end

# Import custom config.
import_config "custom*.exs"
