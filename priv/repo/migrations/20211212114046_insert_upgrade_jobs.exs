defmodule Asciinema.Repo.Migrations.InsertUpgradeJobs do
  use Ecto.Migration
  alias Asciinema.Repo
  alias Asciinema.Upgrades, as: U
  alias Ecto.Multi

  def up do
    {:ok, _} =
      Multi.new()
      |> Multi.insert(:seed, job(U.InitialSeed))
      |> Multi.insert(:asciicasts, job(U.UpgradeAsciicasts))
      |> Repo.transaction()
  end

  def down, do: :ok

  defp job(worker) do
    Oban.Job.new(%{}, queue: :upgrades, worker: worker)
  end
end
