import Config

env = &System.get_env/1

if config_env() in [:prod, :dev] do
  if secret_key_base = env.("SECRET_KEY_BASE") do
    config :asciinema, AsciinemaWeb.Endpoint, secret_key_base: secret_key_base
    config :asciinema, Asciinema.Accounts, secret: secret_key_base
  end

  if url_scheme = env.("URL_SCHEME") do
    config :asciinema, AsciinemaWeb.Endpoint, url: [scheme: url_scheme]
  end

  if url_host = env.("URL_HOST") do
    config :asciinema, AsciinemaWeb.Endpoint, url: [host: url_host]
  end

  if url_port = env.("URL_PORT") do
    config :asciinema, AsciinemaWeb.Endpoint, url: [port: String.to_integer(url_port)]
  end

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

  if db_pool_size = env.("DB_POOL_SIZE") do
    config :asciinema, Asciinema.Repo, pool_size: String.to_integer(db_pool_size)
  end

  if rsvg_pool_size = env.("RSVG_POOL_SIZE") do
    config :asciinema, Asciinema.PngGenerator.Rsvg, pool_size: String.to_integer(rsvg_pool_size)
  end

  if rsvg_font_family = env.("RSVG_FONT_FAMILY") do
    config :asciinema, Asciinema.PngGenerator.Rsvg, font_family: rsvg_font_family
  end

  if gc_days = env.("ASCIICAST_GC_DAYS") do
    config :asciinema, :asciicast_gc_days, String.to_integer(gc_days)
  end

  if String.downcase("#{env.("CRON")}") in ["0", "false", "no"] do
    config :asciinema, Oban, plugins: [{Oban.Plugins.Cron, crontab: []}]
  end

  if env.("SIGN_UP_DISABLED") in ["1", "true"] do
    config :asciinema, :sign_up_enabled?, false
  end

  if dsn = env.("SENTRY_DSN") do
    config :sentry, dsn: dsn
  else
    config :sentry, included_environments: []
  end
end
