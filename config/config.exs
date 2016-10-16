# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :asciinema,
  ecto_repos: [Asciinema.Repo]

# Configures the endpoint
config :asciinema, Asciinema.Endpoint,
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE") || "60BnXnzGGwwiZj91YA9XYKF9BCiM7lQ/1um8VXcWWLSdUp9OcPZV6YnQv7eFTYSY",
  render_errors: [view: Asciinema.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Asciinema.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :template_engines,
  md: PhoenixMarkdown.Engine

config :bugsnag, api_key: System.get_env("BUGSNAG_API_KEY")
config :bugsnag, release_stage: Mix.env

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
