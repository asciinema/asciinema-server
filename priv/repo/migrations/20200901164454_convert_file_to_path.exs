defmodule Asciinema.Repo.Migrations.ConvertFileToPath do
  use Ecto.Migration

  def change do
    rename table(:asciicasts), :file, to: :path

    execute "UPDATE asciicasts SET path=concat('asciicast/file/', id, '/', path) WHERE path IS NOT NULL"
  end
end
