defmodule Asciinema.Repo.Migrations.AddTermVersionToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :term_version, :string
    end
  end
end
