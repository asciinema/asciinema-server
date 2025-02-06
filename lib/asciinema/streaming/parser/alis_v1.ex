defmodule Asciinema.Streaming.Parser.AlisV1 do
  @moduledoc """
  asciinema live stream protocol v1 parser.
  """

  alias Asciinema.Leb128

  @behaviour Asciinema.Streaming.Parser

  def name, do: "v1.alis"

  def init, do: %{status: :new, time_offset: 0}

  def parse({:binary, "ALiS\x01"}, %{status: :new} = state) do
    {:ok, [], %{state | status: :init}}
  end

  def parse({:binary, "ALiS" <> rest}, %{status: :new}) do
    {:error, "unsupported ALiS version/configuration: #{inspect(rest)}"}
  end

  def parse({:binary, <<0x01::8, rest::binary>>}, %{status: status} = state)
      when status in [:init, :eot] do
    init = parse_init(rest)

    {:ok, [init: init], %{state | status: :online, time_offset: init.time}}
  end

  def parse({:binary, <<?o, rest::binary>>}, %{status: :online} = state) do
    {time, text} = parse_output(rest)
    time = state.time_offset + time

    {:ok, [output: {time, text}], %{state | time_offset: time}}
  end

  def parse({:binary, <<?i, rest::binary>>}, %{status: :online} = state) do
    {time, text} = parse_input(rest)
    time = state.time_offset + time

    {:ok, [input: {time, text}], %{state | time_offset: time}}
  end

  def parse({:binary, <<?r, rest::binary>>}, %{status: :online} = state) do
    {time, size} = parse_resize(rest)
    time = state.time_offset + time

    {:ok, [resize: {time, size}], %{state | time_offset: time}}
  end

  def parse({:binary, <<?m, rest::binary>>}, %{status: :online} = state) do
    {time, label} = parse_marker(rest)
    time = state.time_offset + time

    {:ok, [marker: {time, label}], %{state | time_offset: time}}
  end

  def parse({:binary, <<0x04, rest::binary>>}, %{status: status} = state)
      when status in [:init, :online] do
    time = parse_eot(rest)

    {:ok, [eot: {time, %{}}], %{state | status: :eot}}
  end

  def parse({_type, _payload}, _state) do
    {:error, :message_invalid}
  end

  defp parse_init(bytes) do
    {time, bytes} = decode_varint(bytes)
    {cols, bytes} = decode_varint(bytes)
    {rows, bytes} = decode_varint(bytes)
    {theme, bytes} = parse_theme(bytes)
    {term_init, ""} = parse_string(bytes)

    %{time: time, term_size: {cols, rows}, term_init: term_init, term_theme: theme}
  end

  defp parse_output(bytes) do
    {time, bytes} = decode_varint(bytes)
    {text, ""} = parse_string(bytes)

    {time, text}
  end

  defp parse_input(bytes) do
    {time, bytes} = decode_varint(bytes)
    {text, ""} = parse_string(bytes)

    {time, text}
  end

  defp parse_resize(bytes) do
    {time, bytes} = decode_varint(bytes)
    {cols, bytes} = decode_varint(bytes)
    {rows, ""} = decode_varint(bytes)

    {time, {cols, rows}}
  end

  defp parse_marker(bytes) do
    {time, bytes} = decode_varint(bytes)
    {label, ""} = parse_string(bytes)

    {time, label}
  end

  defp parse_eot(bytes) do
    {time, ""} = decode_varint(bytes)

    time
  end

  defp decode_varint(bytes), do: Leb128.decode(bytes)

  defp parse_string(bytes) do
    {len, bytes} = decode_varint(bytes)
    <<text::binary-size(len), rest::binary>> = bytes

    {text, rest}
  end

  defp parse_theme(bytes) do
    case bytes do
      <<0::8, rest::binary>> ->
        {nil, rest}

      <<8::8, theme::binary-size((2 + 8) * 3), rest::binary>> ->
        {do_parse_theme(theme), rest}

      <<16::8, theme::binary-size((2 + 16) * 3), rest::binary>> ->
        {do_parse_theme(theme), rest}
    end
  end

  defp do_parse_theme(theme) do
    colors = for <<r::8, g::8, b::8 <- theme>>, do: {r, g, b}

    %{
      fg: Enum.at(colors, 0),
      bg: Enum.at(colors, 1),
      palette: Enum.slice(colors, 2..-1//-1)
    }
  end
end
