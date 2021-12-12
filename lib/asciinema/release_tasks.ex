defmodule Asciinema.ReleaseTasks do
  @moduledoc "Release tasks, callable from command line"

  @app :asciinema

  def migrate do
    with_started(fn repo ->
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end)
  end

  def admin_add(emails) when is_binary(emails) do
    emails
    |> String.split(~r/[, ]+/)
    |> admin_add()
  end

  def admin_add(emails) when is_list(emails) do
    with_started(fn _repo ->
      Asciinema.Accounts.add_admins(emails)
      IO.puts("#{Enum.join(emails, ", ")} added to admin users list")
    end)
  end

  def admin_rm(emails) when is_binary(emails) do
    emails
    |> String.split(~r/[, ]+/)
    |> admin_rm()
  end

  def admin_rm(emails) when is_list(emails) do
    with_started(fn _repo ->
      Asciinema.Accounts.remove_admins(emails)
      IO.puts("#{Enum.join(emails, ", ")} removed from admin users list")
    end)
  end

  defp with_started(f) do
    Application.ensure_all_started(:ssl)
    [repo] = repos()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, f)

    :ok
  end

  defp repos do
    _ = Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
