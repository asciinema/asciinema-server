defmodule Asciinema.ReleaseTasks do
  @moduledoc "Release tasks, callable from command line"

  @app :asciinema

  def setup do
    with_repo(fn repo ->
      migrate(repo)
      seed()
    end)
  end

  def upgrade do
    with_repo(fn repo ->
      migrate(repo)
      seed()
      upgrade_data()
    end)
  end

  def migrate(repo) do
    Ecto.Migrator.run(repo, :up, all: true)
  end

  def rollback(repo, version) do
    Ecto.Migrator.run(repo, :down, to: version)
  end

  def seed do
    seed_script = Path.join([
      to_string(:code.priv_dir(:asciinema)),
      "repo",
      "seeds.exs"
    ])

    if File.exists?(seed_script) do
      IO.puts("Running seed script..")
      Code.eval_file(seed_script)
    end
  end

  def upgrade_data do
    IO.puts("Upgrading data...")
    Asciinema.Asciicasts.upgrade()
  end

  def admin_add(emails) when is_binary(emails) do
    emails
    |> String.split(~r/[, ]+/)
    |> admin_add()
  end

  def admin_add(emails) when is_list(emails) do
    with_repo(fn _repo ->
      Asciinema.Accounts.add_admins(emails)
      IO.puts "#{Enum.join(emails, ", ")} added to admin users list"
    end)
  end

  def admin_rm(emails) when is_binary(emails) do
    emails
    |> String.split(~r/[, ]+/)
    |> admin_rm()
  end

  def admin_rm(emails) when is_list(emails) do
    with_repo(fn _repo ->
      Asciinema.Accounts.remove_admins(emails)
      IO.puts "#{Enum.join(emails, ", ")} removed from admin users list"
    end)
  end

  defp with_repo(f) do
    [repo] = repos()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, f)
    :ok
  end

  defp repos do
    _ = Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
