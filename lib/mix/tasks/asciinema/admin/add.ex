defmodule Mix.Tasks.Asciinema.Admin.Add do
  use Mix.Task

  @shortdoc "Adds user with given email address to admin users list"
  def run(emails) do
    Mix.Ecto.ensure_started(Asciinema.Repo, [])
    Asciinema.Accounts.add_admins(emails)
    IO.puts "#{emails} added to admin users list"
  end
end
