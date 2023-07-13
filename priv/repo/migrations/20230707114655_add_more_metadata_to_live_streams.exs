defmodule Asciinema.Repo.Migrations.AddMoreMetadataToLiveStreams do
  use Ecto.Migration

  def change do
    alter table(:live_streams) do
      add :private, :boolean, default: true, null: false
      add :secret_token, :string
      add :title, :string
      add :description, :text
      add :theme_name, :string
      add :terminal_line_height, :float
      add :terminal_font_family, :string
    end

    execute(
      fn ->
        %{rows: rows} = repo().query!("SELECT id FROM live_streams")

        for [stream_id] <- rows do
          token = Crypto.random_token(25)

          repo().query!("UPDATE live_streams SET secret_token = $1 WHERE id = $2", [
            token,
            stream_id
          ])
        end
      end,
      fn -> :ok end
    )

    alter table(:live_streams) do
      modify :secret_token, :string, null: false
    end

    create index(:live_streams, [:private])
    create unique_index(:live_streams, [:secret_token])
  end
end
