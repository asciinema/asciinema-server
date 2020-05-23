# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :asciinema,
  ecto_repos: [Asciinema.Repo]

config :asciinema, Asciinema.Repo,
  migration_timestamps: [type: :naive_datetime_usec]

# Configures the endpoint
config :asciinema, AsciinemaWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: AsciinemaWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Asciinema.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger,
  backends: [:console, Sentry.LoggerBackend]

config :phoenix, :template_engines,
  md: PhoenixMarkdown.Engine

config :phoenix, :json_library, Jason

config :sentry,
  dsn: "https://public:secret@sentry.io/1",
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  included_environments: [],
  in_app_module_whitelist: [Asciinema]

config :asciinema, :file_store, Asciinema.FileStore.Local
config :asciinema, Asciinema.FileStore.Local, path: "uploads/"

config :asciinema, :png_generator, Asciinema.PngGenerator.Rsvg
config :asciinema, Asciinema.PngGenerator.Rsvg,
  pool_size: 2,
  font_family: "monospace"

config :asciinema, :snapshot_updater, Asciinema.Asciicasts.SnapshotUpdater.Exq

config :exq,
  name: Exq,
  start_on_application: false,
  url: "redis://localhost:6379",
  namespace: "exq",
  concurrency: 10,
  queues: ["default", "emails"],
  scheduler_enable: true,
  max_retries: 25,
  shutdown_timeout: 5000,
  middleware: [Exq.Middleware.Stats, Exq.Middleware.Job, Exq.Middleware.Manager,
               Exq.Middleware.Logger, Asciinema.Exq.Middleware.Sentry]

config :exq_ui, server: false

config :scrivener_html,
  view_style: :bootstrap_v4

config :asciinema, Asciinema.Scheduler,
  jobs: [
    {"0 * * * *", {Asciinema.GC, :run, []}}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
