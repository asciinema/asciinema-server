defmodule Asciinema.Streaming.Parser do
  @callback name() :: binary
  @callback init() :: term
  @callback parse({message :: term, opts :: keyword}, term) ::
              {:ok, [{atom, term}], term} | {:error, term}

  alias Asciinema.Streaming.Parser

  def get("raw"), do: %{impl: Parser.Raw, state: Parser.Raw.init()}
  def get("v1.alis"), do: %{impl: Parser.AlisV1, state: Parser.AlisV1.init()}
  def get("v2.asciicast"), do: %{impl: Parser.AsciicastV2, state: Parser.AsciicastV2.init()}
  def get("v3.asciicast"), do: %{impl: Parser.AsciicastV3, state: Parser.AsciicastV3.init()}
end
