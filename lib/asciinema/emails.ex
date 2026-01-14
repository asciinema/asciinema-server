defmodule Asciinema.Emails do
  alias Asciinema.Emails.{Email, Mailer}
  require Logger

  def send_email(:sign_up, to, token, url_provider) do
    url = url_provider.sign_up(token)

    to
    |> Email.sign_up_email(url)
    |> deliver()
  end

  def send_email(:login, to, token, url_provider) do
    url = url_provider.login(token)

    to
    |> Email.login_email(url)
    |> deliver()
  end

  def send_email(:email_change, to, token, url_provider) do
    url = url_provider.email_change(token)

    to
    |> Email.email_change_email(url)
    |> deliver()
  end

  def send_email(:account_deletion, to, token, url_provider) do
    url = url_provider.account_deletion(token)

    to
    |> Email.account_deletion_email(url)
    |> deliver()
  end

  def send_email(:test, to) do
    to
    |> Email.test_email()
    |> deliver()
  end

  defp deliver(email) do
    with {:ok, _metadata} <- Mailer.deliver(email) do
      if Mailer.local_adapter?() do
        Enum.each(extract_urls(email), fn url ->
          Logger.info("url from email: #{url}")
        end)
      end

      :ok
    end
  end

  defp extract_urls(email) do
    ~r/"(https?:[^"]+)"/
    |> Regex.scan(email.html_body || email.text_body)
    |> Enum.map(&Enum.at(&1, 1))
  end
end
