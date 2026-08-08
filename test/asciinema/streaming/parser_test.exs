defmodule Asciinema.Streaming.ParserTest do
  use ExUnit.Case, async: true

  alias Asciinema.Streaming.Parser

  describe "new/1 and name/1" do
    test "creates parsers for all supported protocols" do
      for protocol <- ["raw", "v1.alis", "v2.asciicast", "v3.asciicast"] do
        assert protocol |> Parser.new() |> Parser.name() == protocol
      end
    end
  end

  describe "supports?/2" do
    test "reports whether the protocol supports a command" do
      assert Parser.supports?(Parser.new("v1.alis"), :eot)
      refute Parser.supports?(Parser.new("raw"), :eot)
    end
  end

  describe "parse/3" do
    test "delegates parsing and retains updated parser state" do
      parser = Parser.new("raw")

      assert {:ok, [init: %{term_init: "hello"}], parser} =
               Parser.parse(parser, {:binary, "hello"}, 1_000)

      assert {:ok, [output: %{id: 1, time: 500, text: " world"}], _parser} =
               Parser.parse(parser, {:binary, " world"}, 1_500)
    end
  end

  describe "detect/1" do
    test "detects alis v1" do
      assert Parser.detect({:binary, "ALiS\x01"}) == "v1.alis"
    end

    test "detects asciicast v2" do
      assert Parser.detect({:text, ~s|{"version": 2}|}) == "v2.asciicast"
    end

    test "detects asciicast v3" do
      assert Parser.detect({:text, ~s|{"version": 3}|}) == "v3.asciicast"
    end

    test "falls back to raw for other binary data" do
      assert Parser.detect({:binary, "hello"}) == "raw"
    end

    test "falls back to raw for other text" do
      assert Parser.detect({:text, ~s|{}|}) == "raw"
      assert Parser.detect({:text, ~s|hola!|}) == "raw"
    end
  end
end
