defmodule Asciinema do
  alias Asciinema.{Accounts, Asciicasts, Emails}

  def send_login_email(email_or_username, signup_url, login_url) do
    with {:ok, user} <- Accounts.lookup_user(email_or_username) do
      case user do
        %{email: nil} ->
          {:error, :email_missing}

        %{id: nil, email: email} ->
          url = email |> Accounts.signup_token() |> signup_url.()
          {:ok, _} = Emails.send_signup_email(email, url)
          :ok

        user ->
          url = user |> Accounts.login_token() |> login_url.()
          {:ok, _} = Emails.send_login_email(user.email, url)
          :ok
      end
    end
  end

  def merge_accounts(src_user, dst_user) do
    Asciinema.Repo.transaction(fn ->
      Asciicasts.reassign_asciicasts(src_user.id, dst_user.id)
      Accounts.reassign_api_tokens(src_user.id, dst_user.id)
      Accounts.delete_user!(src_user)
      Accounts.get_user(dst_user.id)
    end)
  end
end
