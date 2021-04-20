use Mix.Config

# Configure your database
config :asciinema, Asciinema.Repo,
  username: "postgres",
  password: "postgres",
  database: "asciinema_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

if db_url = System.get_env("TEST_DATABASE_URL") do
  System.put_env("DATABASE_URL", db_url)
end

# Print only errors during test
config :logger, level: :error

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :asciinema, AsciinemaWeb.Endpoint,
  http: [port: 4001],
  secret_key_base: "ssecretkeybasesecretkeybasesecretkeybasesecretkeybaseecretkeybase",
  server: false

config :asciinema, Asciinema.Accounts,
  secret: "ssecretkeybasesecretkeybasesecretkeybasesecretkeybaseecretkeybase"

config :asciinema, Asciinema.FileStore.Local, path: "uploads/test/"

config :asciinema, :snapshot_updater, Asciinema.Asciicasts.SnapshotUpdater.Noop

config :asciinema, Oban, queues: false, plugins: false

config :asciinema, Asciinema.Emails.Mailer, adapter: Bamboo.TestAdapter
