defmodule Asciinema.Repo.Migrations.AddAudioUrlToAsciicastsAndStreams do
  use Ecto.Migration

  def change do
    alter table(:asciicasts) do
      add :audio_url, :string
    end

    alter table(:streams) do
      add :audio_url, :string
    end
  end
end
