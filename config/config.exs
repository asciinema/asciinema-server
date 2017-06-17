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
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
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

if System.get_env("S3_BUCKET") do
  config :asciinema, :file_store, Asciinema.FileStore.S3

  config :asciinema, Asciinema.FileStore.S3,
    region: System.get_env("S3_REGION"),
    bucket: System.get_env("S3_BUCKET"),
    path: "uploads/"

  config :ex_aws,
    access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
    secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]
else
  config :asciinema, :file_store, Asciinema.FileStore.Local
  config :asciinema, Asciinema.FileStore.Local, path: "uploads/"
end

config :asciinema, :png_generator, Asciinema.PngGenerator.A2png
config :asciinema, Asciinema.PngGenerator.A2png,
  bin_path: System.get_env("A2PNG_BIN_PATH") || "./a2png/a2png.sh",
  pool_size: String.to_integer(System.get_env("A2PNG_POOL_SIZE") || "2")

config :asciinema, :redis_url, System.get_env("REDIS_URL") || "redis://redis:6379"

config :asciinema, :poster_generator, Asciinema.Asciicasts.PosterGenerator.Sidekiq

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
