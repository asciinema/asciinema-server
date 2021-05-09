defmodule Asciinema.Repo.Migrations.AddMoreIndexes do
  use Ecto.Migration

  def change do
    create index(:asciicasts, ["id DESC"],
             where: "archived_at IS NULL AND private = false",
             name: "asciicasts_public_active_id_desc_index"
           )

    create index(:asciicasts, ["views_count DESC"],
             where: "archived_at IS NULL AND private = false",
             name: "asciicasts_public_active_views_count_desc_index"
           )

    create index(:asciicasts, ["(1)"],
             where: "archived_at IS NULL AND private = false",
             name: "asciicasts_public_active_index"
           )

    create index(:users, ["(1)"], where: "email IS NULL", name: "users_anonymous_index")
    create index(:users, [:username])
  end
end
