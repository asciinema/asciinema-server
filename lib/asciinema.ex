defmodule Asciinema do
  alias Asciinema.{Accounts, Recordings, Repo}

  def merge_accounts(src_user, dst_user) do
    Repo.transaction(fn ->
      Recordings.reassign_asciicasts(src_user.id, dst_user.id)
      Accounts.reassign_api_tokens(src_user.id, dst_user.id)
      Accounts.delete_user!(src_user)
      Accounts.get_user(dst_user.id)
    end)
  end
end
