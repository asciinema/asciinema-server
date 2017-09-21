defmodule Asciinema.Repo.Migrations.DropStdinFromAsciicast do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      remove :stdin_data
      remove :stdin_timing
    end
  end
end
