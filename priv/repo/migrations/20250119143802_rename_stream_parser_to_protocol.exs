defmodule Asciinema.Repo.Migrations.RenameStreamParserToProtocol do
  use Ecto.Migration

  def change do
    rename table(:live_streams), :parser, to: :protocol
  end
end
