defmodule Asciinema do
  alias Asciinema.{Accounts, Emails, Recordings, Repo, Streaming}

  def initiate_login(identifier, url_provider, opts \\ []) do
    case Accounts.initiate_login(identifier, opts) do
      {:ok, {type, token, email}} ->
        Emails.send_email(type, email, token, url_provider)

      {:error, _reason} = result ->
        result
    end
  end

  defdelegate confirm_login(token, timezone), to: Accounts
  defdelegate confirm_sign_up(token, timezone), to: Accounts
  defdelegate change_user(user, params \\ %{}, ctx \\ :user), to: Accounts

  def update_user(user, params, ctx \\ :user) do
    with {:ok, user} <- Accounts.update_user(user, params, ctx) do
      Recordings.migrate_files(user)

      {:ok, user}
    end
  end

  def initiate_email_change(user, email, url_provider) do
    with {:ok, {:pending, {email, token}}} <- Accounts.initiate_email_change(user, email) do
      Emails.send_email(:email_change, email, token, url_provider)

      {:ok, {:pending, email}}
    end
  end

  defdelegate confirm_email_change(user, token), to: Accounts

  def register_cli(user, token) do
    case Accounts.register_cli(user, token) do
      {:ok, _cli} ->
        :ok

      {:error, {:needs_merge, tmp_user}} ->
        merge_accounts(tmp_user, user)
        :ok

      {:error, _reason} = result ->
        result
    end
  end

  def revoke_cli(user, id) do
    if cli = Accounts.get_cli(user, id) do
      Accounts.revoke_cli!(cli)
      :ok
    else
      {:error, :not_found}
    end
  end

  def merge_accounts(src_user, dst_user) do
    src_user = Accounts.find_user(src_user)
    dst_user = Accounts.find_user(dst_user)

    Repo.transact(fn ->
      Recordings.reassign_asciicasts(src_user.id, dst_user.id)
      Streaming.reassign_streams(src_user.id, dst_user.id)
      Accounts.reassign_clis(src_user.id, dst_user.id)
      Accounts.delete_user!(src_user)

      {:ok, Accounts.get_user(dst_user.id)}
    end)
  end

  def initiate_account_deletion(user, url_provider) do
    token = Accounts.initiate_account_deletion(user)

    Emails.send_email(:account_deletion, user.email, token, url_provider)
  end

  def confirm_account_deletion(token) when is_binary(token) do
    case Accounts.confirm_account_deletion(token) do
      {:ok, user} -> :ok = delete_user!(user)
      {:error, _} -> {:error, :invalid_token}
    end
  end

  def delete_user!(user) do
    result =
      Repo.transact(fn ->
        Recordings.delete_asciicasts(user)
        Streaming.delete_streams(user)

        {:ok, Accounts.delete_user!(user)}
      end)

    with {:ok, _} <- result, do: :ok
  end

  defdelegate get_stream(id), to: Streaming

  def unclaimed_recording_ttl(mode \\ nil)

  def unclaimed_recording_ttl(nil) do
    unclaimed_recording_ttl(:hide) || unclaimed_recording_ttl(:delete)
  end

  def unclaimed_recording_ttl(mode) do
    Keyword.get(Application.get_env(:asciinema, :unclaimed_recording_ttl, []), mode)
  end

  def hide_unclaimed_recordings(days) do
    t = Timex.shift(Timex.now(), days: -days)
    Recordings.hide_unclaimed_asciicasts(Accounts.temporary_users(), t)
  end

  def delete_unclaimed_recordings(days) do
    t = Timex.shift(Timex.now(), days: -days)
    Recordings.delete_unclaimed_asciicasts(Accounts.temporary_users(), t)
  end
end
