defmodule Asciinema.Repo.Migrations.CreateAdminSavedQueries do
  use Ecto.Migration

  def change do
    create table(:admin_saved_queries) do
      add :entity, :string, null: false
      add :name, :string, null: false
      add :filter, :text, null: false
      add :normalized_filter, :text, null: false
      add :sort, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create constraint(:admin_saved_queries, :admin_saved_queries_entity_check,
             check: "entity in ('users', 'recordings', 'streams')"
           )

    create unique_index(:admin_saved_queries, [:entity, "lower(name)"],
             name: :admin_saved_queries_entity_name_index
           )

    create unique_index(:admin_saved_queries, [:entity, :normalized_filter, :sort],
             name: :admin_saved_queries_entity_filter_sort_index
           )
  end
end
