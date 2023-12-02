import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.

env = &System.get_env/1

if env.("PHX_SERVER") do
  config :asciinema, AsciinemaWeb.Endpoint, server: true
  config :asciinema, AsciinemaWeb.Admin.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :asciinema, Asciinema.Repo, url: database_url
end

if config_env() in [:prod, :dev] do
  if secret_key_base = env.("SECRET_KEY_BASE") do
    config :asciinema, AsciinemaWeb.Endpoint, secret_key_base: secret_key_base
    config :asciinema, Asciinema.Accounts, secret: secret_key_base
  end

  if port = env.("PORT") do
    config :asciinema, AsciinemaWeb.Endpoint, http: [port: String.to_integer(port)]
  end

  if url_scheme = env.("URL_SCHEME") do
    config :asciinema, AsciinemaWeb.Endpoint, url: [scheme: url_scheme]
  end

  if url_host = env.("URL_HOST") do
    config :asciinema, AsciinemaWeb.Endpoint, url: [host: url_host]
  end

  if url_path = env.("URL_PATH") do
    config :asciinema, AsciinemaWeb.Endpoint, url: [path: url_path]
    # this requires path prefix stripping at reverse proxy (nginx) level
  end

  if url_port = env.("URL_PORT") do
    config :asciinema, AsciinemaWeb.Endpoint, url: [port: String.to_integer(url_port)]
  end

  if port = env.("ADMIN_PORT") do
    config :asciinema, AsciinemaWeb.Admin.Endpoint, http: [port: String.to_integer(port)]
  end

  if url_scheme = env.("ADMIN_URL_SCHEME") do
    config :asciinema, AsciinemaWeb.Admin.Endpoint, url: [scheme: url_scheme]
  end

  if url_host = env.("ADMIN_URL_HOST") do
    config :asciinema, AsciinemaWeb.Admin.Endpoint, url: [host: url_host]
  end

  if url_port = env.("ADMIN_URL_PORT") do
    config :asciinema, AsciinemaWeb.Admin.Endpoint, url: [port: String.to_integer(url_port)]
  end

  if ip_limit = env.("IP_RATE_LIMIT") do
    config :asciinema, AsciinemaWeb.PlugAttack,
      ip_limit: String.to_integer(ip_limit),
      ip_period: String.to_integer(env.("IP_RATE_PERIOD") || "1") * 1_000
  end

  config :ex_aws, region: {:system, "AWS_REGION"}

  file_cache_path = env.("FILE_CACHE_PATH")

  if file_cache_path do
    config :asciinema, Asciinema.FileCache, path: file_cache_path
  end

  if env.("S3_BUCKET") do
    config :asciinema, :file_store, Asciinema.FileStore.Cached

    config :asciinema, Asciinema.FileStore.Cached,
      remote_store: Asciinema.FileStore.S3,
      cache_store: Asciinema.FileStore.Local

    config :asciinema, Asciinema.FileStore.S3,
      region: env.("S3_REGION") || env.("AWS_REGION"),
      bucket: env.("S3_BUCKET"),
      path: "uploads/",
      proxy: !!env.("S3_PROXY_ENABLED")

    config :ex_aws,
      access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
      secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]

    config :asciinema, Asciinema.FileStore.Local,
      path: Path.join(file_cache_path || "/var/cache/asciinema", "uploads")
  end

  if db_pool_size = env.("DB_POOL_SIZE") do
    config :asciinema, Asciinema.Repo, pool_size: String.to_integer(db_pool_size)
  end

  if env.("ECTO_IPV6") in ~w(true 1) do
    config :asciinema, Asciinema.Repo, socket_options: [:inet6]
  end

  if smtp_host = env.("SMTP_HOST") do
    config :asciinema, Asciinema.Emails.Mailer,
      adapter: Bamboo.SMTPAdapter,
      server: smtp_host,
      port: 25
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

  if id = env.("HOME_ASCIICAST_ID") do
    config :asciinema, home_asciicast_id: id
  end
end
