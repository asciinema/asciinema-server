defmodule Asciinema.Repo.Migrations.StandardizeTimestampPrecision do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :inserted_at, :utc_datetime, precision: :second
      modify :updated_at, :utc_datetime, precision: :second
    end
    
    alter table(:asciicasts) do
      modify :inserted_at, :utc_datetime, precision: :second
      modify :updated_at, :utc_datetime, precision: :second
    end
    
    alter table(:streams) do
      modify :inserted_at, :utc_datetime, precision: :second
      modify :updated_at, :utc_datetime, precision: :second
    end
    
    alter table(:clis) do
      modify :inserted_at, :utc_datetime, precision: :second
      modify :updated_at, :utc_datetime, precision: :second
    end
  end

  def down do
    alter table(:users) do
      modify :inserted_at, :utc_datetime, precision: :microsecond
      modify :updated_at, :utc_datetime, precision: :microsecond
    end
    
    alter table(:asciicasts) do
      modify :inserted_at, :utc_datetime, precision: :microsecond
      modify :updated_at, :utc_datetime, precision: :microsecond
    end
    
    alter table(:streams) do
      modify :inserted_at, :utc_datetime, precision: :microsecond
      modify :updated_at, :utc_datetime, precision: :microsecond
    end
    
    alter table(:clis) do
      modify :inserted_at, :utc_datetime, precision: :microsecond
      modify :updated_at, :utc_datetime, precision: :microsecond
    end
  end
end
