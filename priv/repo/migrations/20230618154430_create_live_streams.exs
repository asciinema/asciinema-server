defmodule Asciinema.Repo.Migrations.CreateLiveStreams do
  use Ecto.Migration

  def change do
    create table(:live_streams) do
      add :user_id, references(:users), null: false
      add :producer_token, :string, null: false
      add :cols, :integer
      add :rows, :integer
      add :last_activity_at, :naive_datetime
      timestamps()
    end

    execute(
      fn ->
        %{rows: rows} = repo().query!("SELECT id FROM users")

        for [user_id] <- rows do
          token = Crypto.random_token(25)
          timestamp = Timex.now()

          repo().query!(
            "INSERT INTO live_streams (user_id, producer_token, inserted_at, updated_at) VALUES ($1, $2, $3, $3)",
            [
              user_id,
              token,
              timestamp
            ]
          )
        end
      end,
      fn -> :ok end
    )
  end
end
