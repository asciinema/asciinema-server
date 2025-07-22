defmodule Asciinema.Repo.Migrations.AddEnvToStreams do
  use Ecto.Migration

  def change do
    alter table(:streams) do
      add :env, :map
    end

    execute("CREATE INDEX streams_env_index ON streams USING GIN(env)", "DROP INDEX streams_env_index")
  end
end
