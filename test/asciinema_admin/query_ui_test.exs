defmodule AsciinemaAdmin.QueryUITest do
  use ExUnit.Case, async: true

  alias AsciinemaAdmin.{QueryParser, QueryUI}

  @entities [:users, :recordings, :streams]

  describe "filter catalog" do
    test "documents exactly the tokens the parser accepts" do
      for entity <- @entities do
        documented = QueryUI.filters(entity) |> Enum.map(& &1.token) |> Enum.sort()
        accepted = QueryParser.tokens(entity) |> Enum.sort()

        assert documented == accepted,
               "#{entity}: documented #{inspect(documented)} != parser #{inspect(accepted)}"
      end
    end

    test "every documented example parses without errors" do
      for entity <- @entities, f <- QueryUI.filters(entity) do
        parsed = QueryParser.parse(entity, f.example)

        assert parsed.errors == [],
               "#{entity} #{f.token} example #{inspect(f.example)}: #{inspect(parsed.errors)}"
      end
    end

    test "every documented autocomplete value parses without errors" do
      for entity <- @entities, f <- QueryUI.filters(entity), value <- f.values do
        q = "#{f.token}:#{value}"
        parsed = QueryParser.parse(entity, q)

        assert parsed.errors == [], "#{entity} #{q}: #{inspect(parsed.errors)}"
      end
    end
  end
end
