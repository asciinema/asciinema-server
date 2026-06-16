defmodule Asciinema.Streaming.Parser.AlisV1Test do
  use ExUnit.Case, async: true
  alias Asciinema.Streaming.Parser.AlisV1
  alias Asciinema.Leb128

  describe "parse/2" do
    test "non-magic-string as the first message" do
      assert parse(new(), "invalid") == {:error, :message_invalid}
    end

    test "non-init as the second message" do
      result =
        new()
        |> parse!("ALiS\x01")
        |> parse(<<"o", encode_output(1, 100, "hello")::binary>>)

      assert result == {:error, :message_invalid}
    end

    test "init" do
      result =
        new()
        |> parse!("ALiS\x01")
        |> parse(<<0x01, encode_init(0, 0, 80, 24, nil, "")::binary>>)

      assert {:ok,
              [init: %{last_id: 0, time: 0, term_size: {80, 24}, term_init: "", term_theme: nil}],
              _state} = result
    end

    test "init with theme" do
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

      theme = %{
        fg: {170, 170, 170},
        bg: {187, 187, 187},
        palette: expected_palette
      }

      result =
        new()
        |> parse!("ALiS\x01")
        |> parse(<<0x01, encode_init(0, 0, 20, 5, theme, "")::binary>>)

      assert {:ok,
              [
                init: %{
                  last_id: 0,
                  time: 0,
                  term_size: {20, 5},
                  term_init: "",
                  term_theme: ^theme
                }
              ], _state} = result
    end

    test "output" do
      result =
        new()
        |> parse!("ALiS\x01")
        |> parse!(<<0x01, encode_init(0, 0, 80, 24, nil, "")::binary>>)
        |> parse(<<"o", encode_output(1, 100_000, "hello")::binary>>)

      assert {:ok, [output: %{id: 1, time: 100_000, text: "hello"}], _state} = result
    end

    test "input" do
      result =
        new()
        |> parse!("ALiS\x01")
        |> parse!(<<0x01, encode_init(0, 0, 80, 24, nil, "")::binary>>)
        |> parse(<<"i", encode_input(1, 100_000, "h")::binary>>)

      assert {:ok, [input: %{id: 1, time: 100_000, text: "h"}], _state} = result
    end

    test "resize" do
      result =
        new()
        |> parse!("ALiS\x01")
        |> parse!(<<0x01, encode_init(0, 0, 80, 24, nil, "")::binary>>)
        |> parse(<<"r", encode_resize(1, 100_000, 120, 30)::binary>>)

      assert {:ok, [resize: %{id: 1, time: 100_000, term_size: {120, 30}}], _state} = result
    end

    test "marker" do
      result =
        new()
        |> parse!("ALiS\x01")
        |> parse!(<<0x01, encode_init(0, 0, 80, 24, nil, "")::binary>>)
        |> parse(<<"m", encode_marker(1, 100_000, "intro")::binary>>)

      assert {:ok, [marker: %{id: 1, time: 100_000, label: "intro"}], _state} = result
    end

    test "exit" do
      result =
        new()
        |> parse!("ALiS\x01")
        |> parse!(<<0x01, encode_init(0, 0, 80, 24, nil, "")::binary>>)
        |> parse(<<"x", encode_exit(1, 100_000, 0)::binary>>)

      assert {:ok, [exit: %{id: 1, time: 100_000, status: 0}], _state} = result
    end

    test "eot" do
      result =
        new()
        |> parse!("ALiS\x01")
        |> parse!(<<0x01, encode_init(0, 0, 80, 24, nil, "")::binary>>)
        |> parse(<<0x04, encode_eot(1, 100_000)::binary>>)

      assert {:ok, [eot: %{id: 1, time: 100_000}], _state} = result
    end

    test "invalid" do
      result =
        new()
        |> parse!("ALiS\x01")
        |> parse!(<<0x01, encode_init(0, 0, 80, 24, nil, "")::binary>>)
        |> parse(<<"z", "invalid">>)

      assert result == {:error, :message_invalid}
    end

    test "id and time" do
      result =
        new()
        |> parse!("ALiS\x01")
        |> parse!(<<0x01, encode_init(0, 0, 80, 24, nil, "")::binary>>)
        |> parse!(<<"o", encode_output(1, 100_000, "hello")::binary>>)
        |> parse!(<<"i", encode_input(2, 200_000, "h")::binary>>)
        |> parse!(<<"r", encode_resize(3, 300_000, 120, 30)::binary>>)
        |> parse(<<"m", encode_marker(4, 400_000, "intro")::binary>>)

      assert {:ok, [marker: %{id: 4, time: 1_000_000, label: "intro"}], _state} = result
    end
  end

  defp new, do: AlisV1.init()

  defp parse(state, binary) do
    AlisV1.parse({:binary, binary}, state)
  end

  defp parse!(state, binary) do
    {:ok, _actions, state} = AlisV1.parse({:binary, binary}, state)
    state
  end

  defp encode_init(last_id, time, cols, rows, theme, term_init) do
    theme_data = if theme, do: encode_theme(theme), else: <<0>>

    <<
      Leb128.encode(last_id)::binary,
      Leb128.encode(time)::binary,
      Leb128.encode(cols)::binary,
      Leb128.encode(rows)::binary,
      theme_data::binary,
      encode_string(term_init)::binary
    >>
  end

  defp encode_output(id, time, text) do
    <<
      Leb128.encode(id)::binary,
      Leb128.encode(time)::binary,
      encode_string(text)::binary
    >>
  end

  defp encode_input(id, time, text) do
    <<
      Leb128.encode(id)::binary,
      Leb128.encode(time)::binary,
      encode_string(text)::binary
    >>
  end

  defp encode_resize(id, time, cols, rows) do
    <<
      Leb128.encode(id)::binary,
      Leb128.encode(time)::binary,
      Leb128.encode(cols)::binary,
      Leb128.encode(rows)::binary
    >>
  end

  defp encode_marker(id, time, label) do
    <<
      Leb128.encode(id)::binary,
      Leb128.encode(time)::binary,
      encode_string(label)::binary
    >>
  end

  defp encode_exit(id, time, status) do
    <<
      Leb128.encode(id)::binary,
      Leb128.encode(time)::binary,
      Leb128.encode(status)::binary
    >>
  end

  defp encode_eot(id, time) do
    <<
      Leb128.encode(id)::binary,
      Leb128.encode(time)::binary
    >>
  end

  defp encode_string(string) do
    len = byte_size(string)
    <<Leb128.encode(len)::binary, string::binary>>
  end

  defp encode_theme(nil), do: <<0>>

  defp encode_theme(%{fg: fg, bg: bg, palette: palette}) do
    palette_size = length(palette)
    colors = [fg, bg | palette]
    binary_colors = for {r, g, b} <- colors, into: <<>>, do: <<r::8, g::8, b::8>>
    <<palette_size::8, binary_colors::binary>>
  end
end
