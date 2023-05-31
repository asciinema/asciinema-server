defmodule Asciinema.Repo.Migrations.AddMarkersToAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :markers, :text
    end
  end
end
