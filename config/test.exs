import Config

# Configure your database
config :asciinema, Asciinema.Repo,
  username: "postgres",
  password: "postgres",
  database: "asciinema_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# In test we don't send emails.
config :asciinema, Asciinema.Emails.Mailer, adapter: Swoosh.Adapters.Test

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

config :asciinema, Asciinema.FileCache, path: "/tmp/asciinema/"

config :asciinema, Oban, testing: :manual

config :asciinema, Asciinema.Telemetry, enabled: false
