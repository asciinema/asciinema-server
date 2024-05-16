defmodule Asciinema.Emails do
  alias Asciinema.Emails.{Email, Mailer}

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
    with {:ok, _email} <- Mailer.deliver_now(email) do
      :ok
    end
  end
end
