defmodule Asciinema.Repo.Migrations.AddUserAgentAndShellToStreams do
  use Ecto.Migration

  def change do
    alter table(:streams) do
      add :user_agent, :string
      add :shell, :string
    end
  end
end
