defmodule Asciinema.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :asciinema

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def admin_add(emails) when is_binary(emails) do
    emails
    |> String.split(~r/[, ]+/)
    |> admin_add()
  end

  def admin_add(emails) when is_list(emails) do
    load_app()

    Ecto.Migrator.with_repo(Asciinema.Repo, fn _repo ->
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
    load_app()

    Ecto.Migrator.with_repo(Asciinema.Repo, fn _repo ->
      Asciinema.Accounts.remove_admins(emails)
      IO.puts("#{Enum.join(emails, ", ")} removed from admin users list")
    end)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
    Application.ensure_all_started(:ssl)
  end
end
