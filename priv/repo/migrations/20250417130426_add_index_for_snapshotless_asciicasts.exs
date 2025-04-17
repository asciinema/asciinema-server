defmodule Asciinema.Repo.Migrations.AddIndexForSnapshotlessAsciicasts do
  use Ecto.Migration

  def change do
    create index(:asciicasts, ["(1)"], where: "snapshot IS NULL", name: "asciicasts_snapshotless_index")
  end
end
