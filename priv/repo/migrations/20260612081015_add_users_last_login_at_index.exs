defmodule Asciinema.Repo.Migrations.AddUsersLastLoginAtIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  # id tiebreak matters: most users have NULL last_login_at, and paginating into
  # that tie block would otherwise re-sort it.
  def change do
    create index(:users, ["last_login_at DESC NULLS LAST", "id DESC"],
             name: "users_last_login_at_index",
             concurrently: true
           )
  end
end
