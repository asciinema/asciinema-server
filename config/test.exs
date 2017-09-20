use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :asciinema, AsciinemaWeb.Endpoint,
  http: [port: 4001],
  secret_key_base: "ssecretkeybasesecretkeybasesecretkeybasesecretkeybaseecretkeybase",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :asciinema, Asciinema.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "asciinema_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :asciinema, :file_store, Asciinema.FileStore.Local
config :asciinema, Asciinema.FileStore.Local, path: "uploads/test/"

config :asciinema, :snapshot_updater, Asciinema.Asciicasts.SnapshotUpdater.Sync
config :asciinema, :frames_generator, Asciinema.Asciicasts.FramesGenerator.Noop

config :exq_ui, server: false

config :asciinema, Asciinema.Mailer,
  adapter: Bamboo.TestAdapter
