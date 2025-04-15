defmodule Asciinema.Repo.Migrations.AddTermTypeAndVersionToStreams do
  use Ecto.Migration

  def change do
    alter table(:streams) do
      add :term_type, :string
      add :term_version, :string
    end
  end
end
