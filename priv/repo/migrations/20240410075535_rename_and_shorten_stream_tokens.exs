defmodule Asciinema.Repo.Migrations.RenameAndShortenStreamTokens do
  use Ecto.Migration

  def change do
    rename table(:live_streams), :secret_token, to: :public_token

    execute "UPDATE live_streams SET public_token = LEFT(public_token, 16), producer_token = LEFT(producer_token, 16)"
  end
end
