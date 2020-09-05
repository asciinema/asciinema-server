defmodule Asciinema.Repo do
  use Ecto.Repo,
    otp_app: :asciinema,
    adapter: Ecto.Adapters.Postgres

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

  def pages(query, page_size) do
    Stream.iterate(:ok, & &1)
    |> Stream.scan({nil, nil}, fn _, {last_id, _} ->
      items = page(query, last_id, page_size)
      last = List.last(items)
      {last && last.id, items}
    end)
    |> Stream.map(& elem(&1, 1))
    |> Stream.take_while(& length(&1) > 0)
  end

  defp page(query, last_id, page_size) do
    import Ecto.Query

    query =
      from x in query,
        order_by: x.id,
        limit: ^page_size

    query =
      case last_id do
        nil ->
          query

        id ->
          where(query, [x], x.id > ^id)
      end

    all(query)
  end
end
