defmodule Asciinema.Emails.Email do
  use Bamboo.Phoenix, view: AsciinemaWeb.EmailView
  import Bamboo.Email

  def signup_email(email_address, signup_url) do
    hostname = instance_hostname()

    email =
      base_email()
      |> to(email_address)
      |> subject("Welcome to #{hostname}")
      |> render("signup.text", signup_url: signup_url, hostname: hostname)
      |> render("signup.html", signup_url: signup_url, hostname: hostname)

    %{email | text_body: String.replace(email.text_body, "\n", "\r\n")}
  end

  def login_email(email_address, login_url) do
    hostname = instance_hostname()

    email =
      base_email()
      |> to(email_address)
      |> subject("Login to #{hostname}")
      |> render("login.text", login_url: login_url, hostname: hostname)
      |> render("login.html", login_url: login_url, hostname: hostname)

    %{email | text_body: String.replace(email.text_body, "\n", "\r\n")}
  end

  def test_email(email_address) do
    hostname = instance_hostname()

    base_email()
    |> to(email_address)
    |> subject("Test email from #{hostname}")
    |> text_body("It works!")
  end

  defp base_email do
    new_email()
    |> from({"asciinema", from_address()})
    |> put_header("Date", Timex.format!(Timex.now(), "{RFC1123}"))
    |> put_header("Reply-To", reply_to_address())
    |> put_html_layout({AsciinemaWeb.LayoutView, "email.html"})
  end

  defp from_address do
    System.get_env("SMTP_FROM_ADDRESS") || "hello@#{instance_hostname()}"
  end

  defp reply_to_address do
    System.get_env("SMTP_REPLY_TO_ADDRESS") || "admin@#{instance_hostname()}"
  end

  defp instance_hostname do
    System.get_env("URL_HOST") || "localhost"
  end
end
