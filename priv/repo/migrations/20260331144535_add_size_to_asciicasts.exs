defmodule Asciinema.Repo.Migrations.AddSizeToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :uncompressed_size, :integer
      add :compressed_size, :integer
    end
  end
end
