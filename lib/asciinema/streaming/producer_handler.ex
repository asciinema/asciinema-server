defmodule Asciinema.Streaming.ProducerHandler do
  @callback init() :: term
  @callback parse({message :: term, opts :: keyword}, term) ::
              {:ok, [{atom, term}], term} | {:error, term}

  alias Asciinema.Streaming.ProducerHandler

  def get(:raw), do: %{impl: ProducerHandler.Raw, state: ProducerHandler.Raw.init()}
  def get(:json), do: %{impl: ProducerHandler.Json, state: ProducerHandler.Json.init()}
end
