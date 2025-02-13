defmodule Asciinema.Streaming.Parser.AlisV0 do
  @moduledoc """
  asciinema live stream protocol v0 parser.

  A prototype protocol, used by 3.0 RC CLI. 
  TODO: Remove after release of the final CLI 3.0
  """

  @behaviour Asciinema.Streaming.Parser

  def name, do: "v0.alis"

  def init, do: %{status: :new}

  def parse({:binary, "ALiS\x01"}, %{status: :new} = state) do
    {:ok, [], %{state | status: :init}}
  end

  def parse({:binary, "ALiS" <> rest}, %{status: :new}) do
    {:error, "unsupported ALiS version/configuration: #{inspect(rest)}"}
  end

  def parse(
        {
          :binary,
          <<
            # message type: init
            1::8,
            # terminal width in columns
            cols::little-16,
            # terminal height in rows
            rows::little-16,
            # current stream time
            time::little-float-32,
            # theme format: none
            0::8,
            # length of the vt init payload
            init_len::little-32,
            # vt init payload
            init::binary-size(init_len)
          >>
        },
        %{status: status} = state
      )
      when status in [:init, :eot] do
    commands = [
      init: %{
        time: time_as_micros(time),
        term_size: {cols, rows},
        term_init: init
      }
    ]

    {:ok, commands, %{state | status: :online}}
  end

  def parse(
        {
          :binary,
          <<
            # message type: init
            1::8,
            # terminal width in columns
            cols::little-16,
            # terminal height in rows
            rows::little-16,
            # current stream time
            time::little-float-32,
            # theme format: 16 color palette, legacy variant, used by RC CLIs
            1::8,
            # theme colors
            theme::binary-size((2 + 16) * 3),
            # length of the vt init payload
            init_len::little-32,
            # vt init payload
            init::binary-size(init_len)
          >>
        },
        %{status: status} = state
      )
      when status in [:init, :eot] do
    commands = [
      init: %{
        time: time_as_micros(time),
        term_size: {cols, rows},
        term_init: init,
        term_theme: parse_theme(theme)
      }
    ]

    {:ok, commands, %{state | status: :online}}
  end

  def parse(
        {
          :binary,
          <<
            # message type: output
            ?o,
            # current stream time
            time::little-float-32,
            # output length
            text_len::little-32,
            # output payload
            text::binary-size(text_len)
          >>
        },
        %{status: :online} = state
      ) do
    {:ok, [output: {time_as_micros(time), text}], state}
  end

  def parse(
        {
          :binary,
          <<
            # message type: input
            ?i,
            # current stream time
            time::little-float-32,
            # input length
            text_len::little-32,
            # input payload
            text::binary-size(text_len)
          >>
        },
        %{status: :online} = state
      ) do
    {:ok, [input: {time_as_micros(time), text}], state}
  end

  def parse(
        {
          :binary,
          <<
            # message type: resize
            ?r,
            # current stream time
            time::little-float-32,
            # terminal width in columns
            cols::little-16,
            # terminal height in rows
            rows::little-16
          >>
        },
        %{status: :online} = state
      ) do
    {:ok, [resize: {time_as_micros(time), {cols, rows}}], state}
  end

  def parse(
        {
          :binary,
          <<
            # message type: marker
            ?m,
            # current stream time
            time::little-float-32,
            # marker label length
            label_len::little-32,
            # marker label payload
            label::binary-size(label_len)
          >>
        },
        %{status: :online} = state
      ) do
    {:ok, [marker: {time_as_micros(time), label}], state}
  end

  def parse({:binary, <<0x04>>}, %{status: status} = state) when status in [:init, :online] do
    {:ok, [eot: %{}], %{state | status: :eot}}
  end

  def parse({_type, _payload}, _state) do
    {:error, :message_invalid}
  end

  defp parse_theme(theme) do
    colors = for <<r::8, g::8, b::8 <- theme>>, do: {r, g, b}

    %{
      fg: Enum.at(colors, 0),
      bg: Enum.at(colors, 1),
      palette: Enum.drop(colors, 2)
    }
  end

  defp time_as_micros(time), do: round(time * 1_000_000)
end
