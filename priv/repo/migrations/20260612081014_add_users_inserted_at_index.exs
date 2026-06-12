defmodule Asciinema.Repo.Migrations.AddUsersInsertedAtIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:users, [:inserted_at], concurrently: true)
  end
end
