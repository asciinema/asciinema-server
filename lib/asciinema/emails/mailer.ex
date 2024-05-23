defmodule Asciinema.Emails.Mailer do
  use Swoosh.Mailer, otp_app: :asciinema

  def local_adapter? do
    Keyword.fetch!(Application.fetch_env!(:asciinema, __MODULE__), :adapter) ==
      Swoosh.Adapters.Local
  end
end
