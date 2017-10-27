defmodule Asciinema.Repo.Migrations.AddRecordedAtToAsciicast do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :recorded_at, :naive_datetime
    end
  end
end
