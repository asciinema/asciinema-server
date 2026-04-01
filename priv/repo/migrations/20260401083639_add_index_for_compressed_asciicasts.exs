defmodule Asciinema.Repo.Migrations.AddIndexForCompressedAsciicasts do
  use Ecto.Migration

  def change do
    create index(:asciicasts, [:compressed])
  end
end
