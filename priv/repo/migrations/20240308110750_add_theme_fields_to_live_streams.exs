defmodule Asciinema.Repo.Migrations.AddThemeFieldsToLiveStreams do
  use Ecto.Migration

  def change do
    alter table(:live_streams) do
      add :theme_fg, :string
      add :theme_bg, :string
      add :theme_palette, :string
    end
  end
end
