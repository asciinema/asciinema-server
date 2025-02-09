defmodule Asciinema.Repo.Migrations.RemoveLegacyStdoutFromAsciicasts do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      remove :stdout_data
      remove :stdout_timing
    end
  end
end
