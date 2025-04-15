defmodule Asciinema.Repo.Migrations.AddDefaultStreamVisibilityToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :default_stream_visibility, :stream_visibility, null: false, default: "unlisted"
    end
  end
end
