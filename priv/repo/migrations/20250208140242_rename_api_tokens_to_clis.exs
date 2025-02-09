defmodule Asciinema.Repo.Migrations.RenameApiTokensToClis do
  use Ecto.Migration

  def change do
    rename table(:api_tokens), to: table(:clis)
    rename index(:clis, [:token], name: "api_tokens_pkey"), to: "clis_pkey"
    rename index(:clis, [:token], name: "index_api_tokens_on_token"), to: "clis_token_index"
    rename index(:clis, [:token], name: "index_api_tokens_on_user_id"), to: "clis_user_id_index"
  end
end
