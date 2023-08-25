defmodule Asciinema.Streaming.Parser do
  @callback init() :: term
  @callback parse({message :: term, opts :: keyword}, term) ::
              {:ok, [{atom, term}], term} | {:error, term}

  alias Asciinema.Streaming.Parser

  def get(:raw), do: %{impl: Parser.Raw, state: Parser.Raw.init()}
  def get(:alis), do: %{impl: Parser.Alis, state: Parser.Alis.init()}
  def get(:json), do: %{impl: Parser.Json, state: Parser.Json.init()}
end
