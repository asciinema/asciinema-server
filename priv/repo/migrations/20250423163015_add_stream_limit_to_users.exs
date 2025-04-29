defmodule Asciinema.Repo.Migrations.AddStreamLimitToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stream_limit, :integer
    end
  end
end
