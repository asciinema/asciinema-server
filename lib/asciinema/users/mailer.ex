defmodule Asciinema.Users.Mailer do
  @doc "Sends registration email to given address"
  @callback send_register_email(email_address :: String.t, register_url :: String.t) :: :ok | {:error, term}

  @doc "Sends login email to given address"
  @callback send_login_email(email_address :: String.t, login_url :: String.t) :: :ok | {:error, term}

  def send_register_email(email_address, register_url) do
    instance().send_register_email(email_address, register_url)
  end

  def send_login_email(email_address, login_url) do
    instance().send_login_email(email_address, login_url)
  end

  defp instance do
    Application.get_env(:asciinema, :mailer)
  end
end
