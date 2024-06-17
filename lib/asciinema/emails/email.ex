defmodule Asciinema.Emails.Email do
  use Phoenix.Component
  import Swoosh.Email

  def sign_up_email(email_address, url) do
    hostname = instance_hostname()

    base_email()
    |> to(email_address)
    |> subject("Welcome to #{hostname}")
    |> body(sign_up_email_html(%{url: url, hostname: hostname}))
  end

  defp sign_up_email_html(assigns) do
    ~H"""
    <.layout>
      <p>Welcome to <%= @hostname %>!</p>

      <p>Open the following link to setup your account:</p>

      <p><a href={@url}><%= @url %></a></p>

      <p>
        <br />
        If you did not initiate this request, just ignore this email. The request will expire shortly.
      </p>
    </.layout>
    """
  end

  def login_email(email_address, url) do
    hostname = instance_hostname()

    base_email()
    |> to(email_address)
    |> subject("Login to #{hostname}")
    |> body(login_email_html(%{url: url, hostname: hostname}))
  end

  defp login_email_html(assigns) do
    ~H"""
    <.layout>
      <p>Welcome back!</p>

      <p>Open the following link to log in to your <%= @hostname %> account:</p>

      <p><a href={@url}><%= @url %></a></p>

      <p>
        <br />
        If you did not initiate this request, just ignore this email. The request will expire shortly.
      </p>
    </.layout>
    """
  end

  def account_deletion_email(email_address, url) do
    base_email()
    |> to(email_address)
    |> subject("Account deletion")
    |> body(account_deletion_email_html(%{url: url, hostname: instance_hostname()}))
  end

  defp account_deletion_email_html(assigns) do
    ~H"""
    <.layout>
      <p>It seems you have requested deletion of your <%= @hostname %> account.</p>

      <p>If you wish to proceed, open the following link in your browser:</p>

      <p><a href={@url}><%= @url %></a></p>

      <p>
        <br /> If you did not initiate this request, just ignore this email.
      </p>
    </.layout>
    """
  end

  def test_email(email_address) do
    base_email()
    |> to(email_address)
    |> subject("Test email from #{instance_hostname()}")
    |> text_body("It works!")
  end

  defp base_email do
    new()
    |> from({"asciinema", from_address()})
    |> header("Date", Timex.format!(Timex.now(), "{RFC1123}"))
    |> header("Message-ID", message_id())
    |> reply_to(reply_to_address())
  end

  defp message_id do
    id = Crypto.md5(:crypto.strong_rand_bytes(16))

    "<#{id}@#{instance_hostname()}>"
  end

  defp body(email, template) do
    html =
      template
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    html_body(email, html)
  end

  defp layout(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <style>
          body {
            font-family: monospace;
          }
        </style>
      </head>
      <body>
        <%= render_slot(@inner_block) %>
      </body>
    </html>
    """
  end

  defp from_address do
    System.get_env("MAIL_FROM_ADDRESS") || System.get_env("SMTP_FROM_ADDRESS") ||
      "hello@#{instance_hostname()}"
  end

  defp reply_to_address do
    System.get_env("MAIL_REPLY_TO_ADDRESS") || System.get_env("SMTP_REPLY_TO_ADDRESS") ||
      "admin@#{instance_hostname()}"
  end

  defp instance_hostname do
    System.get_env("URL_HOST") || "localhost"
  end
end
