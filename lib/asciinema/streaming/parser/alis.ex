defmodule Asciinema.Streaming.Parser.Alis do
  @behaviour Asciinema.Streaming.Parser

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
            # message type: reset
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
      when status in [:init, :offline] do
    commands = [reset: %{term_size: {cols, rows}, term_init: init, time: time}]

    {:ok, commands, %{state | status: :online}}
  end

  def parse(
        {
          :binary,
          <<
            # message type: reset
            1::8,
            # terminal width in columns
            cols::little-16,
            # terminal height in rows
            rows::little-16,
            # current stream time
            time::little-float-32,
            # theme format: 16 color palette, legacy variant, used by RC CLIs
            # TODO: remove after release of the final CLI 3.0
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
      when status in [:init, :offline] do
    commands = [
      reset: %{
        term_size: {cols, rows},
        term_init: init,
        term_theme: parse_theme(theme),
        time: time
      }
    ]

    {:ok, commands, %{state | status: :online}}
  end

  def parse(
        {
          :binary,
          <<
            # message type: reset
            1::8,
            # terminal width in columns
            cols::little-16,
            # terminal height in rows
            rows::little-16,
            # current stream time
            time::little-float-32,
            # theme format: 8 color palette
            8::8,
            # theme colors
            theme::binary-size((2 + 8) * 3),
            # length of the vt init payload
            init_len::little-32,
            # vt init payload
            init::binary-size(init_len)
          >>
        },
        %{status: status} = state
      )
      when status in [:init, :offline] do
    commands = [
      reset: %{
        term_size: {cols, rows},
        term_init: init,
        term_theme: parse_theme(theme),
        time: time
      }
    ]

    {:ok, commands, %{state | status: :online}}
  end

  def parse(
        {
          :binary,
          <<
            # message type: reset
            1::8,
            # terminal width in columns
            cols::little-16,
            # terminal height in rows
            rows::little-16,
            # current stream time
            time::little-float-32,
            # theme format: 16 color palette
            16::8,
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
      when status in [:init, :offline] do
    commands = [
      reset: %{
        term_size: {cols, rows},
        term_init: init,
        term_theme: parse_theme(theme),
        time: time
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
            data_len::little-32,
            # output payload
            data::binary-size(data_len)
          >>
        },
        %{status: :online} = state
      ) do
    {:ok, [output: {time, data}], state}
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
            data_len::little-32,
            # input payload
            data::binary-size(data_len)
          >>
        },
        %{status: :online} = state
      ) do
    {:ok, [input: {time, data}], state}
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
    {:ok, [resize: {time, {cols, rows}}], state}
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
            data_len::little-32,
            # marker label payload
            data::binary-size(data_len)
          >>
        },
        %{status: :online} = state
      ) do
    {:ok, [marker: {time, data}], state}
  end

  def parse({:binary, <<0x04>>}, %{status: status} = state) when status in [:init, :online] do
    {:ok, [status: :offline], %{state | status: :offline}}
  end

  def parse({_type, _payload}, _state) do
    {:error, :message_invalid}
  end

  defp parse_theme(theme) do
    colors = for <<r::8, g::8, b::8 <- theme>>, do: {r, g, b}

    %{
      fg: Enum.at(colors, 0),
      bg: Enum.at(colors, 1),
      palette: Enum.slice(colors, 2..-1)
    }
  end
end
