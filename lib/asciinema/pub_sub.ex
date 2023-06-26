defmodule Asciinema.PubSub do
  def subscribe(topic) do
    :ok = Phoenix.PubSub.subscribe(__MODULE__, topic)
  end

  def broadcast(topic, payload) do
    :ok = Phoenix.PubSub.broadcast(__MODULE__, topic, payload)
  end
end
