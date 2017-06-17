defmodule Asciinema.SidekiqClient do
  def enqueue(class, args, queue \\ "default") do
    job = %{queue: queue,
            class: class,
            args: args,
            enqueued_at: Timex.now |> Timex.to_unix,
            jid: Crypto.random_token(24),
            retry: true}

    payload = Poison.encode!(job)
    {:ok, _} = Redix.command(:redix, ["LPUSH", "queue:#{queue}", payload])
    :ok
  end
end
