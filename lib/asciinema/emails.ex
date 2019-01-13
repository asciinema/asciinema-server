defmodule Asciinema.Emails do
  alias Asciinema.Emails.{Email, Mailer}

  def send_signup_email(to, url) do
    to
    |> Email.signup_email(url)
    |> Mailer.deliver_later()
  end

  def send_login_email(to, url) do
    to
    |> Email.login_email(url)
    |> Mailer.deliver_later()
  end
end
