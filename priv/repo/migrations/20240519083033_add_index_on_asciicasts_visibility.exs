defmodule Asciinema.Repo.Migrations.AddIndexOnAsciicastsVisibility do
  use Ecto.Migration

  def change do
    create index(:asciicasts, [:visibility])
  end
end
