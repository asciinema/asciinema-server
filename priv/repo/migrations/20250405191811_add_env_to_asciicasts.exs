defmodule Asciinema.Repo.Migrations.AddEnvToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :env, :map
    end

    execute("CREATE INDEX asciicasts_env_index ON asciicasts USING GIN(env)", "DROP INDEX asciicasts_env_index")
  end
end
