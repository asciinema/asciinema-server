use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :asciinema, AsciinemaWeb.Endpoint,
  http: [port: 4001],
  secret_key_base: "ssecretkeybasesecretkeybasesecretkeybasesecretkeybaseecretkeybase",
  server: false

# Print only errors during test
config :logger, level: :error

# Configure your database
if db_url = System.get_env("TEST_DATABASE_URL") do
  System.put_env("DATABASE_URL", db_url)
end

config :asciinema, Asciinema.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "asciinema_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :asciinema, :file_store, Asciinema.FileStore.Local
config :asciinema, Asciinema.FileStore.Local, path: "uploads/test/"

config :asciinema, :snapshot_updater, Asciinema.Asciicasts.SnapshotUpdater.Noop

config :exq,
  url: System.get_env("TEST_REDIS_URL") ||
       System.get_env("REDIS_URL") ||
       "redis://localhost:6379/1"

config :exq_ui, server: false

config :asciinema, Asciinema.Mailer,
  adapter: Bamboo.TestAdapter
