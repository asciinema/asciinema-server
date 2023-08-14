defmodule Asciinema do
  alias Asciinema.{Accounts, Emails, Recordings, Repo, Streaming}

  def create_user(params) do
    with {:ok, user} <- Accounts.create_user(params) do
      Streaming.create_live_stream!(user)

      {:ok, user}
    end
  end

  defdelegate change_user(user, params \\ %{}), to: Accounts
  defdelegate update_user(user, params), to: Accounts

  def create_user_from_signup_token(token) do
    with {:ok, email} <- Accounts.verify_signup_token(token) do
      create_user(%{email: email})
    end
  end

  def send_login_email(identifier, sign_up_enabled?, routes) do
    case Accounts.generate_login_url(identifier, sign_up_enabled?, routes) do
      {:ok, {type, url, email}} ->
        Emails.send_email(type, email, url)

      {:error, _reason} = result ->
        result
    end
  end

  defdelegate verify_login_token(token), to: Accounts

  def merge_accounts(src_user, dst_user) do
    Repo.transact(fn ->
      Recordings.reassign_asciicasts(src_user.id, dst_user.id)
      Streaming.reassign_live_streams(src_user.id, dst_user.id)
      Accounts.reassign_api_tokens(src_user.id, dst_user.id)
      Accounts.delete_user!(src_user)

      {:ok, Accounts.get_user(dst_user.id)}
    end)
  end

  defdelegate get_live_stream(id_or_owner), to: Streaming

  def recording_gc_days do
    Application.get_env(:asciinema, :asciicast_gc_days)
  end

  def archive_unclaimed_recordings(days) do
    t = Timex.shift(Timex.now(), days: -days)
    Recordings.archive_asciicasts(Accounts.temporary_users(), t)
  end
end
