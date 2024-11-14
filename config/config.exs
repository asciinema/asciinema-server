# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :asciinema, version: System.get_env("VERSION")

config :asciinema, :session_opts,
  store: :cookie,
  key: "_asciinema_key",
  signing_salt: "qJL+3s0T",
  same_site: "Lax"

config :asciinema,
  ecto_repos: [Asciinema.Repo]

config :asciinema, Asciinema.Repo, migration_timestamps: [type: :naive_datetime_usec]

# Configures the public endpoint
config :asciinema, AsciinemaWeb.Endpoint,
  http: [
    dispatch: [
      {:_,
       [
         {"/ws/s/:public_token", AsciinemaWeb.LiveStreamConsumerSocket, []},
         {"/ws/S/:producer_token", AsciinemaWeb.LiveStreamProducerSocket, []},
         {:_, Plug.Cowboy.Handler, {AsciinemaWeb.Endpoint, []}}
       ]}
    ]
  ],
  url: [host: "localhost"],
  render_errors: [
    formats: [
      html: AsciinemaWeb.ErrorHTML,
      json: AsciinemaWeb.ErrorJSON,
      txt: AsciinemaWeb.ErrorTEXT,
      svg: AsciinemaWeb.ErrorTEXT,
      xml: AsciinemaWeb.ErrorTEXT
    ],
    layout: false
  ],
  live_view: [signing_salt: "F3BMP7k9SZ-Y2SMJ"],
  pubsub_server: Asciinema.PubSub

# Configures the admin endpoint
config :asciinema, AsciinemaWeb.Admin.Endpoint,
  url: [host: "localhost"],
  live_view: [signing_salt: "F3BMP7k9SZ-Y2SMJ"],
  pubsub_server: Asciinema.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger,
  backends: [:console, Sentry.LoggerBackend]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix, :template_engines, md: PhoenixMarkdown.Engine

config :phoenix_template, :format_encoders,
  cast: Jason,
  svg: Phoenix.HTML.Engine,
  xml: Phoenix.HTML.Engine

config :mime, :types, %{
  "application/x-asciicast" => ["cast"]
}

config :asciinema, Asciinema.Emails.Mailer, adapter: Swoosh.Adapters.Local

config :sentry,
  dsn: "https://public:secret@sentry.io/1",
  environment_name: config_env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{env: config_env()},
  in_app_module_allow_list: [Asciinema]

config :asciinema, Asciinema.FileStore, adapter: Asciinema.FileStore.Local
config :asciinema, Asciinema.FileStore.Local, path: "uploads/"

config :asciinema, Asciinema.FileCache, path: "cache/"

config :asciinema, Asciinema.PngGenerator, adapter: Asciinema.PngGenerator.Rsvg

config :asciinema, Asciinema.PngGenerator.Rsvg,
  pool_size: 2,
  font_family: "monospace"

config :asciinema, AsciinemaWeb.DefaultAvatar, adapter: AsciinemaWeb.DefaultAvatar.Identicon

config :asciinema, Oban,
  repo: Asciinema.Repo,
  queues: [default: 10, emails: 10, upgrades: 1],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 604_800},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 * * * *", Asciinema.GC},
       {"* * * * *", Asciinema.Streaming.GC}
     ]},
    Oban.Plugins.Lifeline,
    Oban.Plugins.Reindexer
  ]

config :scrivener_html,
  view_style: :bootstrap_v4

config :tzdata, :autoupdate, :disabled

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
