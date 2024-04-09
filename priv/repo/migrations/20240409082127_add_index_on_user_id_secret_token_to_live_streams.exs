defmodule Asciinema.Repo.Migrations.AddIndexOnUserIdSecretTokenToLiveStreams do
  use Ecto.Migration

  def change do
    create index(:live_streams, [:user_id, :secret_token])
  end
end
