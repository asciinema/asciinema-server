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
    config :asciinema, AsciinemaWeb.Admin.Endpoint, secret_key_base: secret_key_base
    config :asciinema, Asciinema.Accounts, secret: secret_key_base
  end

  if port = env.("PORT") do
    config :asciinema, AsciinemaWeb.Endpoint, http: [port: String.to_integer(port)]
  end

  if url_scheme = env.("URL_SCHEME") do
    config :asciinema, AsciinemaWeb.Endpoint, url: [scheme: url_scheme]

    case url_scheme do
      "http" ->
        config :asciinema, AsciinemaWeb.Endpoint, url: [port: 80]

      "https" ->
        config :asciinema, AsciinemaWeb.Endpoint, url: [port: 443]

      _ ->
        :ok
    end
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

  if env.("ADMIN_BIND_ALL") do
    config :asciinema, AsciinemaWeb.Admin.Endpoint, http: [ip: {0, 0, 0, 0}]
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

  cache_path = env.("CACHE_PATH")

  if cache_path do
    config :asciinema, Asciinema.FileCache, path: cache_path
  end

  config :ex_aws,
    region: [{:system, "S3_REGION"}, {:system, "AWS_REGION"}],
    access_key_id: [
      {:system, "S3_ACCESS_KEY_ID"},
      {:system, "AWS_ACCESS_KEY_ID"},
      :instance_role
    ],
    secret_access_key: [
      {:system, "S3_SECRET_ACCESS_KEY"},
      {:system, "AWS_SECRET_ACCESS_KEY"},
      :instance_role
    ]

  if bucket = env.("S3_BUCKET") do
    config :asciinema, Asciinema.FileStore.S3,
      bucket: bucket,
      path: "uploads/",
      proxy: !!env.("S3_PROXY_ENABLED")

    config :asciinema, Asciinema.FileStore, adapter: Asciinema.FileStore.Cached

    config :asciinema, Asciinema.FileStore.Cached,
      remote_store: Asciinema.FileStore.S3,
      cache_store: Asciinema.FileStore.Local

    config :asciinema, Asciinema.FileStore.Local,
      path: Path.join(cache_path || "/var/cache/asciinema", "uploads")

    if endpoint = env.("S3_ENDPOINT") do
      uri = URI.parse(endpoint)

      config :ex_aws, :s3,
        scheme: "#{uri.scheme}://",
        host: uri.host,
        port: uri.port
    end
  end

  if db_pool_size = env.("DB_POOL_SIZE") do
    config :asciinema, Asciinema.Repo, pool_size: String.to_integer(db_pool_size)
  end

  if env.("ECTO_IPV6") in ~w(true 1) do
    config :asciinema, Asciinema.Repo, socket_options: [:inet6]
  end

  if smtp_host = env.("SMTP_HOST") do
    config :asciinema, Asciinema.Emails.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: smtp_host,
      port: String.to_integer(env.("SMTP_PORT") || "587")

    if username = env.("SMTP_USERNAME") do
      config :asciinema, Asciinema.Emails.Mailer, username: username
    end

    if password = env.("SMTP_PASSWORD") do
      config :asciinema, Asciinema.Emails.Mailer, password: password
    end

    if auth = env.("SMTP_AUTH") do
      config :asciinema, Asciinema.Emails.Mailer, auth: auth
    end

    if tls = env.("SMTP_TLS") do
      config :asciinema, Asciinema.Emails.Mailer, tls: tls
    end

    if versions = env.("SMTP_ALLOWED_TLS_VERSIONS") do
      config :asciinema, Asciinema.Emails.Mailer, allowed_tls_versions: versions
    end

    if retries = env.("SMTP_RETRIES") do
      config :asciinema, Asciinema.Emails.Mailer, retries: String.to_integer(retries)
    end

    if no_mx_lookups = env.("SMTP_NO_MX_LOOKUPS") do
      config :asciinema, Asciinema.Emails.Mailer, no_mx_lookups: no_mx_lookups
    end
  end

  if rsvg_pool_size = env.("RSVG_POOL_SIZE") do
    config :asciinema, Asciinema.PngGenerator.Rsvg, pool_size: String.to_integer(rsvg_pool_size)
  end

  if rsvg_font_family = env.("RSVG_FONT_FAMILY") do
    config :asciinema, Asciinema.PngGenerator.Rsvg, font_family: rsvg_font_family
  end

  if limit = env.("UPLOAD_SIZE_LIMIT") do
    config :asciinema, AsciinemaWeb.Plug.Parsers.MULTIPART, length: String.to_integer(limit)
  end

  if ttls = env.("UNCLAIMED_RECORDING_TTL") do
    ttls =
      case String.split(ttls, ",", parts: 2) do
        [delete_ttl] ->
          [delete: String.to_integer(delete_ttl)]

        [delete_ttl, delete_ttl] ->
          [delete: String.to_integer(delete_ttl)]

        [hide_ttl, delete_ttl] ->
          [hide: String.to_integer(hide_ttl), delete: String.to_integer(delete_ttl)]
      end

    config :asciinema, :unclaimed_recording_ttl, ttls
  end

  if String.downcase("#{env.("CRON")}") in ["0", "false", "no"] do
    config :asciinema, Oban, plugins: [{Oban.Plugins.Cron, crontab: []}]
  end

  if env.("SIGN_UP_DISABLED") in ["1", "true"] do
    config :asciinema, Asciinema.Accounts, sign_up_enabled?: false
  end

  case env.("DEFAULT_AVATAR") do
    "identicon" ->
      config :asciinema, AsciinemaWeb.DefaultAvatar, adapter: AsciinemaWeb.DefaultAvatar.Identicon

    "gravatar" ->
      config :asciinema, AsciinemaWeb.DefaultAvatar, adapter: AsciinemaWeb.DefaultAvatar.Gravatar

    nil ->
      :ok
  end

  if dsn = env.("SENTRY_DSN") do
    config :sentry, dsn: dsn
  else
    config :sentry, included_environments: []
  end

  if email = env.("CONTACT_EMAIL_ADDRESS") do
    config :asciinema, contact_email_address: email
  end
end
