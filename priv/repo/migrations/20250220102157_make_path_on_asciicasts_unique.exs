defmodule Asciinema.Repo.Migrations.MakePathOnAsciicastsUnique do
  use Ecto.Migration

  def change do
    create unique_index(:asciicasts, [:path])
  end
end
