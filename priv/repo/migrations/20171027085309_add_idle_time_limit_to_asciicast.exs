defmodule Asciinema.Repo.Migrations.AddIdleTimeLimitToAsciicast do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :idle_time_limit, :float
    end
  end
end
