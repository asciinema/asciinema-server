defmodule Asciinema.Streaming.Parser.AsciicastV3Test do
  use ExUnit.Case, async: true
  alias Asciinema.Streaming.Parser.AsciicastV3

  describe "parse/2" do
    test "non-init as the first message" do
      assert parse(new(), ~s|[0.1, "o", "hello"]|) == {:error, :init_expected}
    end

    test "init" do
      result = parse(new(), ~s|{"term": {"cols": 80, "rows": 24}}|)

      assert {:ok, [init: %{last_id: 0, time: 0, term_size: {80, 24}, term_theme: nil}], _state} =
               result
    end

    test "init with theme" do
      result =
        parse(
          new(),
          ~s|{"term": {"cols": 20, "rows": 5, "theme": {"fg": "#aaaaaa", "bg": "#bbbbbb", "palette": "#151515:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#d0d0d0:#505050:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#f5f5f5"}}}|
        )

      expected_palette = [
        {21, 21, 21},
        {172, 65, 66},
        {126, 142, 80},
        {229, 181, 103},
        {108, 153, 187},
        {159, 78, 133},
        {125, 214, 207},
        {208, 208, 208},
        {80, 80, 80},
        {172, 65, 66},
        {126, 142, 80},
        {229, 181, 103},
        {108, 153, 187},
        {159, 78, 133},
        {125, 214, 207},
        {245, 245, 245}
      ]

      assert {:ok,
              [
                init: %{
                  last_id: 0,
                  time: 0,
                  term_size: {20, 5},
                  term_theme: %{
                    fg: {170, 170, 170},
                    bg: {187, 187, 187},
                    palette: ^expected_palette
                  }
                }
              ], _state} = result
    end

    test "output" do
      result =
        new()
        |> parse!(~s|{"term": {"cols": 80, "rows": 24}}|)
        |> parse(~s|[0.1, "o", "hello"]|)

      assert {:ok, [output: %{id: 1, time: 100_000, text: "hello"}], _state} = result
    end

    test "input" do
      result =
        new()
        |> parse!(~s|{"term": {"cols": 80, "rows": 24}}|)
        |> parse(~s|[0.1, "i", "h"]|)

      assert {:ok, [input: %{id: 1, time: 100_000, text: "h"}], _state} = result
    end

    test "resize" do
      result =
        new()
        |> parse!(~s|{"term": {"cols": 80, "rows": 24}}|)
        |> parse(~s|[0.1, "r", "120x30"]|)

      assert {:ok, [resize: %{id: 1, time: 100_000, term_size: {120, 30}}], _state} = result
    end

    test "marker" do
      result =
        new()
        |> parse!(~s|{"term": {"cols": 80, "rows": 24}}|)
        |> parse(~s|[0.1, "m", "intro"]|)

      assert {:ok, [marker: %{id: 1, time: 100_000, label: "intro"}], _state} = result
    end

    test "exit" do
      result =
        new()
        |> parse!(~s|{"term": {"cols": 80, "rows": 24}}|)
        |> parse(~s|[0.1, "x", "0"]|)

      assert {:ok, [exit: %{id: 1, time: 100_000, status: 0}], _state} = result
    end

    test "invalid" do
      result =
        new()
        |> parse!(~s|{"term": {"cols": 80, "rows": 24}}|)
        |> parse(~s|[0.1, "o"]|)

      assert result == {:error, :message_invalid}

      result =
        new()
        |> parse!(~s|{"term": {"cols": 80, "rows": 24}}|)
        |> parse(~s|["0.1", "o", "hello"]|)

      assert result == {:error, :message_invalid}

      result =
        new()
        |> parse!(~s|{"term": {"cols": 80, "rows": 24}}|)
        |> parse(~s|[0.1, "o", 123]|)

      assert result == {:error, :message_invalid}
    end

    test "id and time" do
      result =
        new()
        |> parse!(~s|{"term": {"cols": 80, "rows": 24}}|)
        |> parse!(~s|[0.1, "o", "hello"]|)
        |> parse!(~s|[0.2, "i", "h"]|)
        |> parse!(~s|[0.3, "r", "120x30"]|)
        |> parse(~s|[0.4, "m", "intro"]|)

      assert {:ok, [{_, %{id: 4, time: 1_000_000}}], _state} = result
    end

    test "comments" do
      assert {:ok, [init: %{last_id: 0, time: 0}], state} =
               parse(new(), ~s|{"term": {"cols": 80, "rows": 24}}|)

      assert {:ok, [], state} = parse(state, "# such comment")

      assert {:ok, [output: %{id: 1, time: 100_000}], state} =
               parse(state, ~s|[0.1, "o", "hello"]|)

      assert {:ok, [], state} = parse(state, "# many comments")
      assert {:ok, [input: %{id: 2, time: 300_000}], state} = parse(state, ~s|[0.2, "i", "h"]|)
      assert {:ok, [], _state} = parse(state, "# wow")
    end
  end

  defp new, do: AsciicastV3.init()

  defp parse(state, text) do
    AsciicastV3.parse({:text, text}, state)
  end

  defp parse!(state, text) do
    {:ok, _actions, state} = AsciicastV3.parse({:text, text}, state)

    state
  end
end
