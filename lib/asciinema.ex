defmodule Asciinema do
  alias Asciinema.{Accounts, Emails}

  def send_login_email(email_or_username, signup_url, login_url) do
    with {:ok, user} <- Accounts.lookup_user(email_or_username) do
      case user do
        %{email: nil} ->
          {:error, :email_missing}

        %{id: nil, email: email} ->
          url = email |> Accounts.signup_token() |> signup_url.()
          Emails.send_signup_email(email, url)
          :ok

        user ->
          url = user |> Accounts.login_token() |> login_url.()
          Emails.send_login_email(user.email, url)
          :ok
      end
    end
  end
end
