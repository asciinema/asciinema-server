defmodule Asciinema.Repo.Migrations.AddCompressedToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :compressed, :boolean, null: false, default: false
    end
  end
end
