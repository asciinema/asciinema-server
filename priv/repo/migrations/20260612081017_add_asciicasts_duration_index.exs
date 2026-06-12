defmodule Asciinema.Repo.Migrations.AddAsciicastsDurationIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:asciicasts, [:duration], concurrently: true)
  end
end
