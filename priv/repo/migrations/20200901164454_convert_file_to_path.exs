defmodule Asciinema.Repo.Migrations.ConvertFileToPath do
  use Ecto.Migration

  def change do
    rename table(:asciicasts), :file, to: :filename

    alter table(:asciicasts) do
      add :path, :string
    end

    execute "UPDATE asciicasts SET path=concat('asciicast/file/', id, '/', filename) WHERE filename IS NOT NULL"
  end
end
