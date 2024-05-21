defmodule Asciinema.Emails do
  alias Asciinema.Emails.{Email, Mailer}
  require Logger

  def send_email(:signup, to, token) do
    to
    |> Email.signup_email(token)
    |> deliver()
  end

  def send_email(:login, to, token) do
    to
    |> Email.login_email(token)
    |> deliver()
  end

  def send_email(:account_deletion, to, token) do
    to
    |> Email.account_deletion_email(token)
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
        for url <- extract_urls(email) do
          Logger.info("url from email: #{url}")
        end
      end

      :ok
    end
  end

  defp extract_urls(email) do
    ~r/"(https?:[^"]+)"/
    |> Regex.scan(email.html_body)
    |> Enum.map(&Enum.at(&1, 1))
  end
end
