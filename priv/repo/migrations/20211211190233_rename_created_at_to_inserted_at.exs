defmodule Asciinema.Repo.Migrations.RenameCreatedAtToInsertedAt do
  use Ecto.Migration

  def change do
    rename table(:users), :created_at, to: :inserted_at
    rename table(:api_tokens), :created_at, to: :inserted_at
    rename table(:asciicasts), :created_at, to: :inserted_at
  end
end
