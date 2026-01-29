defmodule Asciinema.Repo.Migrations.RenameAsciicastsIndexes do
  use Ecto.Migration

  def change do
    execute "ALTER INDEX index_asciicasts_on_created_at RENAME TO asciicasts_created_at_index"
    execute "ALTER INDEX index_asciicasts_on_featured RENAME TO asciicasts_featured_index"
    execute "ALTER INDEX index_asciicasts_on_secret_token RENAME TO asciicasts_secret_token_index"
    execute "ALTER INDEX index_asciicasts_on_user_id RENAME TO asciicasts_user_id_index"
  end
end
