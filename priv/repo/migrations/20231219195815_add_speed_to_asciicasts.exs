defmodule Asciinema.Repo.Migrations.AddSpeedToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :speed, :float
    end
  end
end
