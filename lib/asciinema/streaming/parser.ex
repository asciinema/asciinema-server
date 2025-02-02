defmodule Asciinema.Streaming.Parser do
  @callback name() :: binary
  @callback init() :: term
  @callback parse({message :: term, opts :: keyword}, term) ::
              {:ok, [{atom, term}], term} | {:error, term}

  alias Asciinema.Streaming.Parser

  def get("raw"), do: %{impl: Parser.Raw, state: Parser.Raw.init()}
  def get("v0.alis"), do: %{impl: Parser.AlisV0, state: Parser.AlisV0.init()}
  def get("v1.alis"), do: %{impl: Parser.AlisV1, state: Parser.AlisV1.init()}
  def get("v2.asciicast"), do: %{impl: Parser.Json, state: Parser.Json.init()}
end
