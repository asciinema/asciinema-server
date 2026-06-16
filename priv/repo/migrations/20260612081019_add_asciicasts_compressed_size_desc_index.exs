defmodule Asciinema.Repo.Migrations.AddAsciicastsCompressedSizeDescIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  # compressed_size is nullable and size sorts pin NULLs last in both
  # directions, so the descending direction needs its own index.
  def change do
    create index(:asciicasts, ["compressed_size DESC NULLS LAST", "id DESC"],
             name: "asciicasts_compressed_size_desc_index",
             concurrently: true
           )
  end
end
