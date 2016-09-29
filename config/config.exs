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
  secret_key_base: "cMyA6OaN0/eg6Q9+/0dzdERa3Tqp7BxP/SACWXL+XA+V5MUgf5DirQmX9mFT/iIF",
  render_errors: [view: Asciinema.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Asciinema.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :template_engines,
  md: PhoenixMarkdown.Engine

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
