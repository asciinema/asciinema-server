import Config

## Use Mailgun for mail delivery:

# config :asciinema, Asciinema.Mailer,
#   adapter: Swoosh.Adapters.SMTP,
#   relay: "smtp.mailgun.org",
#   port: 587,
#   username: "postmaster@mg.yourdomain.com",
#   password: "mailgun-password",
#   tls: :if_available, # can be `:always` or `:never`
#   allowed_tls_versions: [:"tlsv1", :"tlsv1.1", :"tlsv1.2"],
#   ssl: false,
#   retries: 1
