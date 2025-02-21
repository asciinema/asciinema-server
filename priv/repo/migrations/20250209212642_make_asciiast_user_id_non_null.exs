defmodule Asciinema.Repo.Migrations.MakeAsciiastUserIdNonNull do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      modify :user_id, references(:users), null: false
    end

    drop constraint(:asciicasts, "asciicasts_user_id_fk")
  end
end
