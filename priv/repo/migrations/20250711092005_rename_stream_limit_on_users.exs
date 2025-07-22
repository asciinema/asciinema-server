defmodule Asciinema.Repo.Migrations.RenameStreamLimitOnUsers do
  use Ecto.Migration

  def change do
    rename table(:users), :stream_limit, to: :live_stream_limit
  end
end
