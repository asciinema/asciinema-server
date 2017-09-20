class MakeSchemaMigrationsCompatWithEcto < ActiveRecord::Migration
  def up
    change_column :schema_migrations, :version, 'bigint USING CAST(version AS bigint)', limit: 8, null: false
    add_column :schema_migrations, :inserted_at, :datetime
    remove_index :schema_migrations, name: "unique_schema_migrations"
    execute "ALTER TABLE schema_migrations ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);"
  end
end
