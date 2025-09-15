defmodule Asciinema.Streaming.Parser.RawTest do
  use ExUnit.Case, async: true
  alias Asciinema.Streaming.Parser.Raw

  describe "parse/2" do
    test "first message without size" do
      result = parse(new(), {:binary, "hello world"})

      assert {:ok, [init: %{last_id: 0, time: 0, term_size: {80, 24}, term_init: "hello world"}],
              state} = result

      refute state.first
    end

    test "first message with size as resize sequence" do
      result = parse(new(), {:binary, "\x1b[8;30;120t"})

      assert {:ok,
              [init: %{last_id: 0, time: 0, term_size: {120, 30}, term_init: "\x1b[8;30;120t"}],
              state} = result

      refute state.first
    end

    test "first message with size as script start message" do
      result =
        parse(
          new(),
          {:script, "Script started on [timestamp] [COLUMNS=\"100\" LINES=\"40\" other stuff]"}
        )

      assert {:ok, [init: %{last_id: 0, time: 0, term_size: {100, 40}, term_init: _}], state} =
               result

      refute state.first
    end

    test "following message" do
      result =
        new()
        |> parse!({:binary, "initial output"})
        |> parse({:binary, "more output"})

      assert {:ok, [output: %{id: 1, time: _time, text: "more output"}], _state} = result
    end

    test "id incrementing" do
      result =
        new()
        |> parse!({:binary, "initial"})
        |> parse!({:binary, "first"})
        |> parse!({:binary, "second"})
        |> parse({:binary, "third"})

      assert {:ok, [output: %{id: 3, time: _time, text: "third"}], _state} = result
    end

    test "text message type works as well" do
      result =
        new()
        |> parse!({:text, "\x1b[8;30;120t"})
        |> parse!({:text, "first"})
        |> parse({:text, "second"})

      assert {:ok, [output: %{id: 2, time: _time, text: "second"}], _state} = result
    end
  end

  defp new, do: Raw.init()

  defp parse(state, message) do
    Raw.parse(message, state)
  end

  defp parse!(state, message) do
    {:ok, _actions, state} = Raw.parse(message, state)

    state
  end
end
