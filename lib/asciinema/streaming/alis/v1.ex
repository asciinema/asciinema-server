defmodule Asciinema.Streaming.Alis.V1 do
  # The ALIS v1 wire format (https://docs.asciinema.org/manual/server/streaming/).
  #
  # Binary layout of ALIS frames, both directions. Frames carry relative
  # times; frame sequencing (what may arrive when) is the parser's concern.
  #
  # Encoding trusts our own stream state and crashes on invalid input;
  # decoding is total - malformed network input returns {:error, reason}.
  #
  # EOT is a bare 0x04 control frame; decoding ignores any legacy trailing
  # payload (one or two varints, depending on the sender's vintage).

  alias Asciinema.Leb128

  @varint_options max_bytes: 10, max_value: 0xFFFF_FFFF_FFFF_FFFF

  def magic, do: "ALiS\x01"

  # Encoding

  def encode_frame({:init, %{last_id: id, time: time, term_size: {cols, rows}} = data}) do
    <<1::8>> <>
      varint(id) <>
      varint(time) <>
      varint(cols) <>
      varint(rows) <>
      encode_theme(data[:term_theme]) <>
      encode_string(data[:term_init] || "")
  end

  def encode_frame({:output, %{id: id, rel_time: time, text: text}}) do
    <<?o>> <> varint(id) <> varint(time) <> encode_string(text)
  end

  def encode_frame({:input, %{id: id, rel_time: time, text: text}}) do
    <<?i>> <> varint(id) <> varint(time) <> encode_string(text)
  end

  def encode_frame({:resize, %{id: id, rel_time: time, term_size: {cols, rows}}}) do
    <<?r>> <> varint(id) <> varint(time) <> varint(cols) <> varint(rows)
  end

  def encode_frame({:marker, %{id: id, rel_time: time, label: label}}) do
    <<?m>> <> varint(id) <> varint(time) <> encode_string(label)
  end

  def encode_frame({:exit, %{id: id, rel_time: time, status: status}}) do
    <<?x>> <> varint(id) <> varint(time) <> varint(status)
  end

  def encode_frame({:eot, %{}}) do
    <<0x04::8>>
  end

  # Decoding

  def decode_frame(<<1::8, rest::binary>>) do
    with {:ok, last_id, rest} <- decode_varint(rest),
         {:ok, time, rest} <- decode_varint(rest),
         {:ok, cols, rest} <- decode_varint(rest),
         {:ok, rows, rest} <- decode_varint(rest),
         {:ok, theme, rest} <- decode_theme(rest),
         {:ok, term_init, rest} <- decode_string(rest),
         :ok <- ensure_done(rest) do
      {:ok,
       {:init,
        %{
          last_id: last_id,
          time: time,
          term_size: {cols, rows},
          term_theme: theme,
          term_init: term_init
        }}}
    end
  end

  def decode_frame(<<?o, rest::binary>>), do: decode_text_event(:output, :text, rest)
  def decode_frame(<<?i, rest::binary>>), do: decode_text_event(:input, :text, rest)
  def decode_frame(<<?m, rest::binary>>), do: decode_text_event(:marker, :label, rest)

  def decode_frame(<<?r, rest::binary>>) do
    with {:ok, id, rest} <- decode_varint(rest),
         {:ok, time, rest} <- decode_varint(rest),
         {:ok, cols, rest} <- decode_varint(rest),
         {:ok, rows, rest} <- decode_varint(rest),
         :ok <- ensure_done(rest) do
      {:ok, {:resize, %{id: id, rel_time: time, term_size: {cols, rows}}}}
    end
  end

  def decode_frame(<<?x, rest::binary>>) do
    with {:ok, id, rest} <- decode_varint(rest),
         {:ok, time, rest} <- decode_varint(rest),
         {:ok, status, rest} <- decode_varint(rest),
         :ok <- ensure_done(rest) do
      {:ok, {:exit, %{id: id, rel_time: time, status: status}}}
    end
  end

  def decode_frame(<<0x04::8, _rest::binary>>) do
    {:ok, {:eot, %{}}}
  end

  def decode_frame(<<type::8, _rest::binary>>), do: {:error, {:unknown_frame_type, type}}
  def decode_frame(<<>>), do: {:error, :empty_frame}

  # Encoding internals

  defp varint(value), do: Leb128.encode(value)

  defp encode_string(text), do: varint(byte_size(text)) <> text

  defp encode_theme(nil), do: <<0::8>>

  defp encode_theme(theme) do
    format = length(theme.palette)
    true = format in [8, 16]

    colors =
      for {r, g, b} <- [theme.fg, theme.bg | theme.palette], into: <<>> do
        <<r::8, g::8, b::8>>
      end

    <<format::8>> <> colors
  end

  # Decoding internals

  defp decode_varint(bytes), do: Leb128.decode(bytes, @varint_options)

  defp decode_text_event(event, field, bytes) do
    with {:ok, id, rest} <- decode_varint(bytes),
         {:ok, time, rest} <- decode_varint(rest),
         {:ok, text, rest} <- decode_string(rest),
         :ok <- ensure_done(rest) do
      {:ok, {event, %{:id => id, :rel_time => time, field => text}}}
    end
  end

  defp decode_string(bytes) do
    with {:ok, len, rest} <- decode_varint(bytes) do
      case rest do
        <<text::binary-size(len), rest::binary>> -> {:ok, text, rest}
        _ -> {:error, :truncated_string}
      end
    end
  end

  defp decode_theme(<<0::8, rest::binary>>), do: {:ok, nil, rest}

  defp decode_theme(<<format::8, rest::binary>>) when format in [8, 16] do
    size = (2 + format) * 3

    case rest do
      <<colors::binary-size(size), rest::binary>> ->
        [fg, bg | palette] = for <<r::8, g::8, b::8 <- colors>>, do: {r, g, b}

        {:ok, %{fg: fg, bg: bg, palette: palette}, rest}

      _ ->
        {:error, :truncated_theme}
    end
  end

  defp decode_theme(<<format::8, _rest::binary>>), do: {:error, {:invalid_theme_format, format}}
  defp decode_theme(<<>>), do: {:error, :truncated_frame}

  defp ensure_done(<<>>), do: :ok
  defp ensure_done(_rest), do: {:error, :trailing_data}
end
