defmodule Asciinema do
  alias Asciinema.{Accounts, Emails, Recordings, Repo, Streaming}

  defdelegate create_user(attrs, ctx \\ :user), to: Accounts

  def create_user_from_sign_up_token(token) do
    with {:ok, email} <- Accounts.verify_sign_up_token(token),
         {:ok, user} <- create_user(%{email: email}) do
      {:ok, user}
    else
      {:error, %Ecto.Changeset{errors: [{:email, _}]}} ->
        {:error, :email_taken}

      result ->
        result
    end
  end

  defdelegate change_user(user, params \\ %{}, ctx \\ :user), to: Accounts

  def update_user(user, params, ctx \\ :user) do
    with {:ok, user} <- Accounts.update_user(user, params, ctx) do
      Recordings.migrate_files(user)

      {:ok, user}
    end
  end

  def send_login_email(identifier, url_provider, opts \\ []) do
    case Accounts.generate_login_token(identifier, opts) do
      {:ok, {type, token, email}} ->
        Emails.send_email(type, email, token, url_provider)

      {:error, _reason} = result ->
        result
    end
  end

  def send_account_deletion_email(user, url_provider) do
    token = Accounts.generate_deletion_token(user)

    Emails.send_email(:account_deletion, user.email, token, url_provider)
  end

  defdelegate generate_login_token(email), to: Accounts
  defdelegate verify_login_token(token), to: Accounts

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

  def delete_user(token) when is_binary(token) do
    with {:ok, user_id} <- Accounts.verify_deletion_token(token),
         user when not is_nil(user) <- Accounts.get_user(user_id) do
      :ok = delete_user!(user)
    else
      _ -> {:error, :invalid_token}
    end
  end

  def delete_user!(user) do
    result =
      Repo.transact(fn ->
        Recordings.delete_asciicasts(user)
        Streaming.delete_streams(user)
        Accounts.delete_user!(user)
      end)

    with {:ok, _} <- result, do: :ok
  end

  defdelegate get_stream(id_or_owner), to: Streaming

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
