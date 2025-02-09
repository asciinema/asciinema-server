defmodule Asciinema.Repo.Migrations.AddCliIdToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :cli_id, references(:clis)
    end

    create index(:asciicasts, [:cli_id])

    execute "UPDATE asciicasts AS a SET cli_id = (SELECT id FROM clis WHERE user_id=a.user_id ORDER BY id LIMIT 1) WHERE a.inserted_at < COALESCE((SELECT inserted_at FROM clis WHERE user_id=a.user_id ORDER BY id OFFSET 1 LIMIT 1), NOW())", ""
  end
end
