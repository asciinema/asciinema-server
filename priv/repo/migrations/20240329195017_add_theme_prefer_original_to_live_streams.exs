defmodule Asciinema.Repo.Migrations.AddThemePreferOriginalToLiveStreams do
  use Ecto.Migration

  def change do
    alter table(:live_streams) do
      add :theme_prefer_original, :boolean, null: false, default: true
    end
  end
end
