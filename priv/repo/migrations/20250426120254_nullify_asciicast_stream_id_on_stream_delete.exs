defmodule Asciinema.Repo.Migrations.NullifyAsciicastStreamIdOnStreamDelete do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      modify :stream_id, references(:streams, on_delete: :nilify_all),
        from: references(:streams, on_delete: :nothing)
    end
  end
end
