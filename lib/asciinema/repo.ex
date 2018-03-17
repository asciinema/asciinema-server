defmodule Asciinema.Repo do
  use Ecto.Repo, otp_app: :asciinema
  use Scrivener, page_size: 10

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end

  def count(query) do
    aggregate(query, :count, :id)
  end
end
