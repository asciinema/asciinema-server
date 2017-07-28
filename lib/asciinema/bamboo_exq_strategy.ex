defmodule Asciinema.BambooExqStrategy do
  @behaviour Bamboo.DeliverLaterStrategy

  def deliver_later(adapter, email, config) do
    binary = [adapter, email, config] |> :erlang.term_to_binary |> Base.encode64
    {:ok, _jid} = Exq.enqueue(Exq, "emails", __MODULE__, [binary])
  end

  def perform(binary) do
    [adapter, email, config] = binary |> Base.decode64! |> :erlang.binary_to_term
    adapter.deliver(email, config)
  end
end
