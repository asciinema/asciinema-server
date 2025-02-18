defmodule Asciinema.Repo.Migrations.AddStreamIdToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :stream_id, references(:streams)
    end

    create index(:asciicasts, [:stream_id])
  end
end
