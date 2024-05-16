defmodule Asciinema.Emails.Email do
  use Bamboo.Phoenix, view: AsciinemaWeb.EmailView
  import Bamboo.Email

  def signup_email(email_address, signup_url) do
    base_email()
    |> to(email_address)
    |> subject("Welcome to #{instance_hostname()}")
    |> render("signup.text", signup_url: signup_url)
    |> render("signup.html", signup_url: signup_url)
    |> fix_text_body()
  end

  def login_email(email_address, login_url) do
    base_email()
    |> to(email_address)
    |> subject("Login to #{instance_hostname()}")
    |> render("login.text", login_url: login_url)
    |> render("login.html", login_url: login_url)
    |> fix_text_body()
  end

  def account_deletion_email(email_address, confirmation_url) do
    base_email()
    |> to(email_address)
    |> subject("Account deletion")
    |> render("account_deletion.text", confirmation_url: confirmation_url)
    |> render("account_deletion.html", confirmation_url: confirmation_url)
    |> fix_text_body()
  end

  def test_email(email_address) do
    base_email()
    |> to(email_address)
    |> subject("Test email from #{instance_hostname()}")
    |> text_body("It works!")
  end

  defp base_email do
    new_email()
    |> from({"asciinema", from_address()})
    |> put_header("Date", Timex.format!(Timex.now(), "{RFC1123}"))
    |> put_header("Reply-To", reply_to_address())
    |> put_html_layout({AsciinemaWeb.LayoutView, "email.html"})
    |> assign(:hostname, instance_hostname())
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

  defp fix_text_body(email) do
    %{email | text_body: String.replace(email.text_body, "\n", "\r\n")}
  end
end
