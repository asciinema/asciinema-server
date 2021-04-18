import Config

env = &System.get_env/1

secret_key_base = env.("SECRET_KEY_BASE")

config :asciinema, AsciinemaWeb.Endpoint,
  url: [
    scheme: env.("URL_SCHEME") || "https",
    host: env.("URL_HOST") || "asciinema.org",
    port: String.to_integer(env.("URL_PORT") || "443")
  ],
  secret_key_base: secret_key_base

config :asciinema, Asciinema.Accounts, secret: secret_key_base

config :asciinema, Asciinema.Repo, pool_size: String.to_integer(env.("DB_POOL_SIZE") || "20")

if env.("S3_BUCKET") do
  config :asciinema, :file_store, Asciinema.FileStore.Cached

  config :asciinema, Asciinema.FileStore.Cached,
    remote_store: Asciinema.FileStore.S3,
    cache_store: Asciinema.FileStore.Local

  config :asciinema, Asciinema.FileStore.S3,
    region: env.("S3_REGION"),
    bucket: env.("S3_BUCKET"),
    path: "uploads/",
    proxy: !!env.("S3_PROXY_ENABLED")

  config :ex_aws,
    access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
    secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]

  config :asciinema, Asciinema.FileStore.Local, path: "cache/uploads/"
end

config :asciinema, Asciinema.PngGenerator.Rsvg,
  pool_size: String.to_integer(env.("RSVG_POOL_SIZE") || "2"),
  font_family: env.("RSVG_FONT_FAMILY") || "monospace"

if dsn = env.("SENTRY_DSN") do
  config :sentry, dsn: dsn
else
  config :sentry, included_environments: []
end

if gc_days = env.("ASCIICAST_GC_DAYS") do
  config :asciinema, :asciicast_gc_days, String.to_integer(gc_days)
end

if String.downcase("#{env.("CRON")}") in ["0", "false", "no"] do
  config :asciinema, Asciinema.Scheduler, jobs: []
end
