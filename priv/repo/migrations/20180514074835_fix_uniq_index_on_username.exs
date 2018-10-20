defmodule Asciinema.Repo.Migrations.FixUniqIndexOnUsername do
  use Ecto.Migration

  def change do
    drop index(:users, [:username], name: "index_users_on_username")
    create unique_index(:users, ["(lower(username))"], name: "index_users_on_username")
  end
end
