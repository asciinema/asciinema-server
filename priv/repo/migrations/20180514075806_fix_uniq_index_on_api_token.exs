defmodule Asciinema.Repo.Migrations.FixUniqIndexOnApiToken do
  use Ecto.Migration

  def change do
    drop index(:api_tokens, [:token], name: "index_api_tokens_on_token")
    create unique_index(:api_tokens, [:token], name: "index_api_tokens_on_token")
  end
end
