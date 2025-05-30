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
    data = parse_output(rest)
    time = state.time_offset + data.time
    data = %{data | time: time}

    {:ok, [output: data], %{state | time_offset: time}}
  end

  def parse({:binary, <<?i, rest::binary>>}, %{status: :online} = state) do
    data = parse_input(rest)
    time = state.time_offset + data.time
    data = %{data | time: time}

    {:ok, [input: data], %{state | time_offset: time}}
  end

  def parse({:binary, <<?r, rest::binary>>}, %{status: :online} = state) do
    data = parse_resize(rest)
    time = state.time_offset + data.time
    data = %{data | time: time}

    {:ok, [resize: data], %{state | time_offset: time}}
  end

  def parse({:binary, <<?m, rest::binary>>}, %{status: :online} = state) do
    data = parse_marker(rest)
    time = state.time_offset + data.time
    data = %{data | time: time}

    {:ok, [marker: data], %{state | time_offset: time}}
  end

  def parse({:binary, <<?x, rest::binary>>}, %{status: :online} = state) do
    data = parse_exit(rest)
    time = state.time_offset + data.time
    data = %{data | time: time}

    {:ok, [exit: data], %{state | time_offset: time}}
  end

  def parse({:binary, <<0x04, rest::binary>>}, %{status: status} = state)
      when status in [:init, :online] do
    %{time: time} = parse_eot(rest)
    time = state.time_offset + time

    {:ok, [eot: {time, %{}}], %{state | status: :eot}}
  end

  def parse({_type, _payload}, _state) do
    {:error, :message_invalid}
  end

  defp parse_init(bytes) do
    {last_id, bytes} = decode_varint(bytes)
    {time, bytes} = decode_varint(bytes)
    {cols, bytes} = decode_varint(bytes)
    {rows, bytes} = decode_varint(bytes)
    {theme, bytes} = parse_theme(bytes)
    {term_init, ""} = parse_string(bytes)

    %{
      last_id: last_id,
      time: time,
      term_size: {cols, rows},
      term_init: term_init,
      term_theme: theme
    }
  end

  defp parse_output(bytes) do
    {id, bytes} = decode_varint(bytes)
    {time, bytes} = decode_varint(bytes)
    {text, ""} = parse_string(bytes)

    %{id: id, time: time, text: text}
  end

  defp parse_input(bytes) do
    {id, bytes} = decode_varint(bytes)
    {time, bytes} = decode_varint(bytes)
    {text, ""} = parse_string(bytes)

    %{id: id, time: time, text: text}
  end

  defp parse_resize(bytes) do
    {id, bytes} = decode_varint(bytes)
    {time, bytes} = decode_varint(bytes)
    {cols, bytes} = decode_varint(bytes)
    {rows, ""} = decode_varint(bytes)

    %{id: id, time: time, term_size: {cols, rows}}
  end

  defp parse_marker(bytes) do
    {id, bytes} = decode_varint(bytes)
    {time, bytes} = decode_varint(bytes)
    {label, ""} = parse_string(bytes)

    %{id: id, time: time, label: label}
  end

  defp parse_exit(bytes) do
    {id, bytes} = decode_varint(bytes)
    {time, bytes} = decode_varint(bytes)
    {status, ""} = decode_varint(bytes)

    %{id: id, time: time, status: status}
  end

  defp parse_eot(bytes) do
    {time, ""} = decode_varint(bytes)

    %{time: time}
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
      palette: Enum.drop(colors, 2)
    }
  end
end
