defmodule Asciinema.Repo.Migrations.AddAsciicastsAudioIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:asciicasts, ["(1)"],
             where: "audio_url IS NOT NULL",
             name: "asciicasts_audio_index",
             concurrently: true
           )
  end
end
