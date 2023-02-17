import Config

# Configure your database
config :asciinema, Asciinema.Repo,
  username: "postgres",
  password: "postgres",
  database: "asciinema_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

if db_url = System.get_env("TEST_DATABASE_URL") do
  System.put_env("DATABASE_URL", db_url)
end

# Print only errors during test
config :logger, level: :error

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :asciinema, AsciinemaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  secret_key_base: "ssecretkeybasesecretkeybasesecretkeybasesecretkeybaseecretkeybase",
  server: false

config :asciinema, Asciinema.Accounts,
  secret: "ssecretkeybasesecretkeybasesecretkeybasesecretkeybaseecretkeybase"

config :asciinema, Asciinema.FileStore.Local, path: "uploads/test/"

config :asciinema, :snapshot_updater, Asciinema.Asciicasts.SnapshotUpdater.Noop

config :asciinema, Oban, testing: :manual

config :asciinema, Asciinema.Emails.Mailer, adapter: Bamboo.TestAdapter

config :asciinema, Asciinema.Telemetry, enabled: false
