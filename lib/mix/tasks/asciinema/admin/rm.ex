defmodule Mix.Tasks.Asciinema.Admin.Rm do
  use Mix.Task

  @shortdoc "Removes user with given email address from admin users list"
  def run(emails) do
    Mix.Ecto.ensure_started(Asciinema.Repo, [])
    Asciinema.Accounts.remove_admins(emails)
    IO.puts "#{emails} removed from admin users list"
  end
end
