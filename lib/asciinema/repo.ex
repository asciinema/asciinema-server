defmodule Asciinema.Repo do
  use Ecto.Repo,
    otp_app: :asciinema,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10

  def init(_type, config) do
    config = Keyword.put(config, :url, System.get_env("DATABASE_URL"))

    config =
      if pool_size = System.get_env("DB_POOL_SIZE") do
        Keyword.put(config, :pool_size, String.to_integer(pool_size))
      else
        config
      end

    config =
      if System.get_env("ECTO_IPV6") in ~w(true 1) do
        Keyword.put(config, :socket_options, [:inet6])
      else
        config
      end

    {:ok, config}
  end

  def transact(fun, opts \\ []) do
    transaction(
      fn ->
        case fun.() do
          {:ok, value} -> value
          :ok -> :transaction_commited
          {:error, reason} -> rollback(reason)
          :error -> rollback(:transaction_rollback_error)
        end
      end,
      opts
    )
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
    |> Stream.map(&elem(&1, 1))
    |> Stream.take_while(&(length(&1) > 0))
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
